import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_metrics.dart';
import '../services/local_storage_service.dart';

class HealthMetricsRepository {
  HealthMetricsRepository({
    required FirebaseAuth? auth,
    required FirebaseFirestore? firestore,
    required LocalStorageService storage,
  })  : _auth = auth,
        _firestore = firestore,
        _storage = storage;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final LocalStorageService _storage;

  String get todayKey => _formatDate(DateTime.now());

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return null;
    }
    return firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>>? get _sleepRef => _userRef?.collection('sleep_logs');
  CollectionReference<Map<String, dynamic>>? get _stepRef => _userRef?.collection('step_logs');
  CollectionReference<Map<String, dynamic>>? get _weightRef => _userRef?.collection('weight_history');
  String? get _uid => _auth?.currentUser?.uid;
  String? get _sleepCacheKey => _uid == null ? null : 'sleep_${_uid!}_$todayKey';
  String? get _stepsCacheKey => _uid == null ? null : 'steps_${_uid!}_$todayKey';
  String? get _weightCacheKey => _uid == null ? null : 'weight_history_${_uid!}';
  String? get _weeklyStepsCacheKey => _uid == null ? null : 'weekly_steps_${_uid!}_${_weekKey(DateTime.now())}';
  String? get _weeklySleepCacheKey => _uid == null ? null : 'weekly_sleep_${_uid!}_${_weekKey(DateTime.now())}';

  Stream<SleepLogRecord?> watchTodaySleep() async* {
    final cacheKey = _sleepCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJson(cacheKey);
      if (cached != null) {
        yield SleepLogRecord.fromJson(cached);
      }
    }

    final ref = _sleepRef?.doc(todayKey);
    if (ref == null) {
      yield null;
      return;
    }

    yield* ref.snapshots().asyncMap((snapshot) async {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      if (cacheKey != null) {
        await _storage.saveJson(cacheKey, data);
      }
      return SleepLogRecord.fromJson(data);
    });
  }

  Stream<StepLogRecord?> watchTodaySteps() async* {
    final cacheKey = _stepsCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJson(cacheKey);
      if (cached != null) {
        yield StepLogRecord.fromJson(cached);
      }
    }

    final ref = _stepRef?.doc(todayKey);
    if (ref == null) {
      yield null;
      return;
    }

    yield* ref.snapshots().asyncMap((snapshot) async {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      if (cacheKey != null) {
        await _storage.saveJson(cacheKey, data);
      }
      return StepLogRecord.fromJson(data);
    });
  }

  Stream<List<WeightHistoryEntry>> watchWeightHistory({int limit = 12}) async* {
    final cacheKey = _weightCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJsonList(cacheKey);
      if (cached.isNotEmpty) {
        yield cached
            .map((item) => WeightHistoryEntry.fromJson(item['id'] as String? ?? '', item))
            .toList();
      }
    }

    final ref = _weightRef;
    if (ref == null) {
      yield const [];
      return;
    }

    yield* ref
        .orderBy('recordedAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final items = snapshot.docs.map((doc) => WeightHistoryEntry.fromJson(doc.id, doc.data())).toList();
      if (cacheKey != null) {
        await _storage.saveJsonList(
          cacheKey,
          items.map((item) => {'id': item.id, ...item.toJson()}).toList(),
        );
      }
      return items;
    });
  }

  Future<void> saveSleep({
    required double hours,
    required String quality,
  }) async {
    final ref = _sleepRef?.doc(todayKey);
    if (ref == null) {
      return;
    }

    await ref.set(
      {
        'hours': hours,
        'quality': quality,
        'dateKey': todayKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveSteps(int steps, {double? activeCalories}) async {
    final ref = _stepRef?.doc(todayKey);
    if (ref == null) {
      return;
    }

    final existing = await ref.get();
    final existingData = existing.data();
    final existingSteps = (existingData?['steps'] as num?)?.toInt() ?? 0;
    final existingActiveCalories = (existingData?['activeCalories'] as num?)?.toDouble() ?? 0;
    final cacheKey = _stepsCacheKey;
    final cachedData = cacheKey == null ? null : await _storage.readJson(cacheKey);
    final cachedSteps = (cachedData?['steps'] as num?)?.toInt() ?? 0;
    final cachedActiveCalories = (cachedData?['activeCalories'] as num?)?.toDouble() ?? 0;
    final nextSteps = [steps, existingSteps, cachedSteps].reduce((value, element) => value > element ? value : element);
    final nextActiveCalories = [
      activeCalories ?? 0,
      existingActiveCalories,
      cachedActiveCalories,
    ].reduce((value, element) => value > element ? value : element);

    await ref.set(
      {
        'steps': nextSteps,
        'activeCalories': nextActiveCalories,
        'dateKey': todayKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (cacheKey != null) {
      await _storage.saveJson(
        cacheKey,
        {
          'steps': nextSteps,
          'activeCalories': nextActiveCalories,
          'dateKey': todayKey,
        },
      );
    }
  }

  Future<void> addWeightEntry(double weightKg) async {
    final ref = _weightRef;
    if (ref == null) {
      return;
    }

    final doc = ref.doc();
    final now = DateTime.now();
    await doc.set(
      {
        'weightKg': weightKg,
        'dateKey': todayKey,
        'recordedAt': now.toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<Map<String, int>> loadCurrentWeekSteps() async {
    final cacheKey = _weeklyStepsCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJson(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached.map((key, value) => MapEntry(key, (value as num).toInt()));
      }
    }

    final ref = _stepRef;
    if (ref == null) {
      return const {};
    }

    final start = _startOfWeek(DateTime.now());
    final end = start.add(const Duration(days: 6));
    final snapshot = await ref
        .where('dateKey', isGreaterThanOrEqualTo: _formatDate(start))
        .where('dateKey', isLessThanOrEqualTo: _formatDate(end))
        .get();

    final byDate = <String, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      byDate[data['dateKey'] as String? ?? ''] = (data['steps'] as num?)?.toInt() ?? 0;
    }
    if (cacheKey != null) {
      await _storage.saveJson(cacheKey, byDate);
    }
    return byDate;
  }

  Future<Map<String, double>> loadCurrentWeekSleep() async {
    final cacheKey = _weeklySleepCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJson(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    }

    final ref = _sleepRef;
    if (ref == null) {
      return const {};
    }

    final start = _startOfWeek(DateTime.now());
    final end = start.add(const Duration(days: 6));
    final snapshot = await ref
        .where('dateKey', isGreaterThanOrEqualTo: _formatDate(start))
        .where('dateKey', isLessThanOrEqualTo: _formatDate(end))
        .get();

    final byDate = <String, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      byDate[data['dateKey'] as String? ?? ''] = (data['hours'] as num?)?.toDouble() ?? 0;
    }
    if (cacheKey != null) {
      await _storage.saveJson(cacheKey, byDate);
    }
    return byDate;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _weekKey(DateTime date) => _formatDate(_startOfWeek(date));

  DateTime _startOfWeek(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.subtract(Duration(days: local.weekday - 1));
  }
}
