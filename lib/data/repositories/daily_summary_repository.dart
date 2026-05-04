import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_summary.dart';
import '../models/food_analysis_result.dart';

class DailySummaryRepository {
  DailySummaryRepository({
    required FirebaseAuth? auth,
    required FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  String get todayKey => _formatDate(DateTime.now());

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return null;
    }
    return firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>>? get _foodLogsRef => _userRef?.collection('food_logs');
  CollectionReference<Map<String, dynamic>>? get _waterLogsRef => _userRef?.collection('water_logs');

  Stream<List<MealLogEntry>> watchTodayMeals() {
    final ref = _foodLogsRef;
    if (ref == null) {
      return Stream.value(const []);
    }

    return ref
        .where('date', isEqualTo: todayKey)
        .orderBy('loggedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MealLogEntry.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<int> watchTodayWater() {
    final ref = _waterLogsRef?.doc(todayKey);
    if (ref == null) {
      return Stream.value(0);
    }

    return ref.snapshots().map((snapshot) {
      final data = snapshot.data();
      return (data?['glasses'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> addMeal(
    FoodAnalysisResult result, {
    String? imagePath,
  }) async {
    final ref = _foodLogsRef;
    if (ref == null) {
      return;
    }

    final loggedAt = DateTime.now();
    final meal = MealLogEntry.fromAnalysis(
      result,
      imagePath: imagePath,
      loggedAt: loggedAt,
    );

    await ref.add(
      {
        ...meal.toJson(),
        'loggedAt': Timestamp.fromDate(loggedAt),
        'date': todayKey,
        'scanResult': result.toJson(),
      },
    );
  }

  Future<void> setWaterCount(int glasses) async {
    final ref = _waterLogsRef?.doc(todayKey);
    if (ref == null) {
      return;
    }

    await ref.set(
      {
        'glasses': glasses.clamp(0, 8),
        'date': todayKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<Map<String, double>> loadCurrentWeekCalories() async {
    final ref = _foodLogsRef;
    if (ref == null) {
      return const {};
    }

    final start = _startOfWeek(DateTime.now());
    final end = start.add(const Duration(days: 6));
    final snapshot = await ref
        .where('date', isGreaterThanOrEqualTo: _formatDate(start))
        .where('date', isLessThanOrEqualTo: _formatDate(end))
        .get();

    final byDate = <String, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String? ?? '';
      final calories = (data['macros'] is Map
              ? ((data['macros'] as Map)['calories'] as num?)
              : data['calories'] as num?)
          ?.toDouble() ??
          0;
      byDate.update(date, (value) => value + calories, ifAbsent: () => calories);
    }
    return byDate;
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
