import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../models/weekly_plan.dart';
import '../services/ai_backend_service.dart';

class PlannerRepository {
  PlannerRepository({
    required FirebaseAuth? auth,
    required FirebaseFirestore? firestore,
    required AiBackendService aiBackendService,
  })  : _auth = auth,
        _firestore = firestore,
        _aiBackendService = aiBackendService;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final AiBackendService _aiBackendService;

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

  Stream<List<WeeklyExerciseItem>> watchTodayExercises() {
    final ref = _exerciseRef;
    if (ref == null) {
      return Stream.value(const []);
    }

    return ref
        .where('dateKey', isEqualTo: todayKey)
        .orderBy('loggedAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WeeklyExerciseItem.fromJson(doc.id, doc.data()))
              .toList(),
        );
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

    final generated = await _aiBackendService.generateExercisePlan(profile: profile);
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

    final generated = await _aiBackendService.generateMealPlan(profile: profile, weekOf: weekKey);
    await ref.set(
      {
        'weekOf': weekKey,
        'generatedAt': FieldValue.serverTimestamp(),
        'plan': generated.toJson(),
      },
      SetOptions(merge: true),
    );
    return generated;
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
}
