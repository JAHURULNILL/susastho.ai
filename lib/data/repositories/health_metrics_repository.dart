import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_metrics.dart';

class HealthMetricsRepository {
  HealthMetricsRepository({
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

  CollectionReference<Map<String, dynamic>>? get _sleepRef => _userRef?.collection('sleep_logs');
  CollectionReference<Map<String, dynamic>>? get _stepRef => _userRef?.collection('step_logs');
  CollectionReference<Map<String, dynamic>>? get _weightRef => _userRef?.collection('weight_history');

  Stream<SleepLogRecord?> watchTodaySleep() {
    final ref = _sleepRef?.doc(todayKey);
    if (ref == null) {
      return Stream.value(null);
    }

    return ref.snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : SleepLogRecord.fromJson(data);
    });
  }

  Stream<StepLogRecord?> watchTodaySteps() {
    final ref = _stepRef?.doc(todayKey);
    if (ref == null) {
      return Stream.value(null);
    }

    return ref.snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : StepLogRecord.fromJson(data);
    });
  }

  Stream<List<WeightHistoryEntry>> watchWeightHistory({int limit = 12}) {
    final ref = _weightRef;
    if (ref == null) {
      return Stream.value(const []);
    }

    return ref
        .orderBy('recordedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WeightHistoryEntry.fromJson(doc.id, doc.data())).toList());
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

  Future<void> saveSteps(int steps) async {
    final ref = _stepRef?.doc(todayKey);
    if (ref == null) {
      return;
    }

    await ref.set(
      {
        'steps': steps,
        'dateKey': todayKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
