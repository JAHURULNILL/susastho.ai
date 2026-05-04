import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../models/weekly_plan.dart';
import '../services/ai_backend_service.dart';
import '../services/local_storage_service.dart';
import 'daily_summary_repository.dart';
import 'health_metrics_repository.dart';

class PlannerRepository {
  PlannerRepository({
    required FirebaseAuth? auth,
    required FirebaseFirestore? firestore,
    required AiBackendService aiBackendService,
    required LocalStorageService storage,
    required DailySummaryRepository dailySummaryRepository,
    required HealthMetricsRepository healthMetricsRepository,
  })  : _auth = auth,
        _firestore = firestore,
        _aiBackendService = aiBackendService,
        _storage = storage,
        _dailySummaryRepository = dailySummaryRepository,
        _healthMetricsRepository = healthMetricsRepository;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final AiBackendService _aiBackendService;
  final LocalStorageService _storage;
  final DailySummaryRepository _dailySummaryRepository;
  final HealthMetricsRepository _healthMetricsRepository;

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return null;
    }
    return firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>>? get _exerciseRef => _userRef?.collection('exercise_logs');
  CollectionReference<Map<String, dynamic>>? get _mealPlanRef => _userRef?.collection('meal_plans');

  String get todayKey => _formatDate(DateTime.now());
  String get weekKey => _formatDate(_startOfWeek(DateTime.now()));
  String? get _uid => _auth?.currentUser?.uid;
  String? get _exerciseCacheKey => _uid == null ? null : 'exercise_${_uid!}_$todayKey';
  String? get _mealPlanCacheKey => _uid == null ? null : 'meal_plan_${_uid!}_$weekKey';

  Stream<List<WeeklyExerciseItem>> watchTodayExercises() async* {
    final cacheKey = _exerciseCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJsonList(cacheKey);
      if (cached.isNotEmpty) {
        yield cached
            .map((item) => WeeklyExerciseItem.fromJson(item['id'] as String? ?? '', item))
            .toList();
      }
    }

    final ref = _exerciseRef;
    if (ref == null) {
      yield const [];
      return;
    }

    yield* ref
        .where('dateKey', isEqualTo: todayKey)
        .orderBy('loggedAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final items = snapshot.docs
          .map((doc) => WeeklyExerciseItem.fromJson(doc.id, doc.data()))
          .toList();
      if (cacheKey != null) {
        await _storage.saveJsonList(
          cacheKey,
          items.map((item) => {'id': item.id, ...item.toJson()}).toList(),
        );
      }
      return items;
    });
  }

  Stream<WeeklyMealPlan?> watchCurrentWeekMealPlan() async* {
    final cacheKey = _mealPlanCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJson(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        yield WeeklyMealPlan.fromJson(cached);
      }
    }

    final ref = _mealPlanRef?.doc(weekKey);
    if (ref == null) {
      yield null;
      return;
    }

    yield* ref.snapshots().asyncMap((snapshot) async {
      final data = snapshot.data();
      if (data == null || data['plan'] is! Map) {
        return null;
      }
      final plan = WeeklyMealPlan.fromJson(
        Map<String, dynamic>.from(data['plan'] as Map),
      );
      if (cacheKey != null) {
        await _storage.saveJson(cacheKey, plan.toJson());
      }
      return plan;
    });
  }

  Future<void> ensureTodayExercises(UserProfile profile) async {
    final ref = _exerciseRef;
    if (ref == null) {
      return;
    }

    final existing = await ref.where('dateKey', isEqualTo: todayKey).limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final generated = await _aiBackendService.generateExercisePlan(
      profile: profile,
      historicalContext: await _historicalContext(),
    );
    if (generated.isEmpty) {
      return;
    }

    final batch = _firestore!.batch();
    for (final item in generated) {
      final doc = ref.doc();
      batch.set(
        doc,
        item.copyWith(
          id: doc.id,
          dateKey: todayKey,
          loggedAt: DateTime.now(),
        ).toJson(),
      );
    }
    await batch.commit();
  }

  Future<void> toggleExercise(String exerciseId, bool completed) async {
    final ref = _exerciseRef?.doc(exerciseId);
    if (ref == null) {
      return;
    }

    await ref.update({'completed': completed});
  }

  Future<WeeklyMealPlan?> getOrGenerateWeeklyMealPlan(UserProfile profile) async {
    final ref = _mealPlanRef?.doc(weekKey);
    if (ref == null) {
      return null;
    }

    final existing = await ref.get();
    final data = existing.data();
    if (data != null && data['plan'] is Map) {
      return WeeklyMealPlan.fromJson(
        Map<String, dynamic>.from(data['plan'] as Map),
      );
    }

    final generated = await _aiBackendService.generateMealPlan(
      profile: profile,
      weekOf: weekKey,
      historicalContext: await _historicalContext(),
    );
    await ref.set(
      {
        'weekOf': weekKey,
        'generatedAt': FieldValue.serverTimestamp(),
        'plan': generated.toJson(),
      },
      SetOptions(merge: true),
    );
    final cacheKey = _mealPlanCacheKey;
    if (cacheKey != null) {
      await _storage.saveJson(cacheKey, generated.toJson());
    }
    return generated;
  }

  Future<void> ensureCurrentWeekMealPlan(UserProfile profile) async {
    final ref = _mealPlanRef?.doc(weekKey);
    if (ref == null) {
      return;
    }

    final existing = await ref.get();
    final data = existing.data();
    if (data != null && data['plan'] is Map) {
      return;
    }

    final generated = await _aiBackendService.generateMealPlan(
      profile: profile,
      weekOf: weekKey,
      historicalContext: await _historicalContext(),
    );
    await ref.set(
      {
        'weekOf': weekKey,
        'generatedAt': FieldValue.serverTimestamp(),
        'plan': generated.toJson(),
      },
      SetOptions(merge: true),
    );
    final cacheKey = _mealPlanCacheKey;
    if (cacheKey != null) {
      await _storage.saveJson(cacheKey, generated.toJson());
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _startOfWeek(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  Future<Map<String, dynamic>> _historicalContext() async {
    final sleep = await _healthMetricsRepository.watchTodaySleep().first;
    final steps = await _healthMetricsRepository.watchTodaySteps().first;
    return {
      ...await _dailySummaryRepository.loadHistoricalContext(),
      'todaySleepHours': sleep?.hours ?? 0,
      'todaySteps': steps?.steps ?? 0,
    };
  }
}
