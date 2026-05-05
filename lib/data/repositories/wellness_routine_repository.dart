import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/wellness_routine.dart';
import '../services/local_storage_service.dart';
import '../services/wellness_backend_service.dart';

class WellnessRoutineRepository {
  WellnessRoutineRepository({
    required FirebaseAuth? auth,
    required FirebaseFirestore? firestore,
    required LocalStorageService storage,
    required WellnessBackendService backendService,
  })  : _auth = auth,
        _firestore = firestore,
        _storage = storage,
        _backendService = backendService;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final LocalStorageService _storage;
  final WellnessBackendService _backendService;

  String get todayKey => _formatDate(DateTime.now());

  String? get _uid => _auth?.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _logsRef => _firestore?.collection('wellness_logs');
  CollectionReference<Map<String, dynamic>>? get _streaksRef => _firestore?.collection('wellness_streaks');
  CollectionReference<Map<String, dynamic>>? get _notesRef => _firestore?.collection('wellness_notes');
  DocumentReference<Map<String, dynamic>>? get _nofapRef {
    final uid = _uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return null;
    }
    return firestore.collection('nofap_tracker').doc(uid);
  }

  String? get _benefitCacheKey => _uid == null ? null : 'wellness_benefit_${_uid!}_$todayKey';

  Stream<Map<WellnessRoutineType, WellnessStreakRecord>> watchStreaks() async* {
    final uid = _uid;
    final ref = _streaksRef;
    if (uid == null || ref == null) {
      yield const {};
      return;
    }

    yield* ref.where('userId', isEqualTo: uid).snapshots().map((snapshot) {
      final next = <WellnessRoutineType, WellnessStreakRecord>{};
      for (final doc in snapshot.docs) {
        final record = WellnessStreakRecord.fromJson(doc.data());
        next[record.moduleId] = record;
      }
      return next;
    });
  }

  Stream<Set<String>> watchTodayLogs() async* {
    final uid = _uid;
    final ref = _logsRef;
    if (uid == null || ref == null) {
      yield const <String>{};
      return;
    }

    yield* ref
        .where('userId', isEqualTo: uid)
        .where('date', isEqualTo: todayKey)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()['moduleId'] as String? ?? '').where((item) => item.isNotEmpty).toSet());
  }

  Stream<Map<String, Set<String>>> watchCurrentWeekLogs() async* {
    final uid = _uid;
    final ref = _logsRef;
    if (uid == null || ref == null) {
      yield const {};
      return;
    }

    final start = _startOfWeek(DateTime.now());
    final end = start.add(const Duration(days: 6));

    yield* ref
        .where('userId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: _formatDate(start))
        .where('date', isLessThanOrEqualTo: _formatDate(end))
        .snapshots()
        .map((snapshot) {
      final grouped = <String, Set<String>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = data['date'] as String? ?? '';
        final moduleId = data['moduleId'] as String? ?? '';
        if (date.isEmpty || moduleId.isEmpty) {
          continue;
        }
        grouped.putIfAbsent(date, () => <String>{}).add(moduleId);
      }
      return grouped;
    });
  }

  Stream<NofapTrackerRecord?> watchNofapTracker() async* {
    final ref = _nofapRef;
    if (ref == null) {
      yield null;
      return;
    }

    yield* ref.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return NofapTrackerRecord.fromJson(data);
    });
  }

  Future<String?> readCachedDailyBenefit() async {
    final key = _benefitCacheKey;
    if (key == null) {
      return null;
    }
    final cached = await _storage.readJson(key);
    return cached?['benefit'] as String?;
  }

  Future<String> fetchDailyBenefit() async {
    final benefit = await _backendService.fetchDailyBenefit();
    final key = _benefitCacheKey;
    if (key != null && benefit.isNotEmpty) {
      await _storage.saveJson(
        key,
        {
          'benefit': benefit,
          'dateKey': todayKey,
        },
      );
    }
    return benefit;
  }

  Future<void> completeModule({
    required WellnessRoutineType moduleId,
    required int duration,
    Map<String, dynamic> details = const {},
  }) async {
    await _backendService.completeModule(
      moduleId: moduleId,
      duration: duration,
      details: details,
    );
  }

  Future<void> resetNofap() => _backendService.resetNofap();

  Future<Map<String, dynamic>> loadWellnessContext() async {
    final uid = _uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return const {};
    }

    final streakSnapshot = await firestore.collection('wellness_streaks').where('userId', isEqualTo: uid).get();
    final todaySnapshot = await firestore
        .collection('wellness_logs')
        .where('userId', isEqualTo: uid)
        .where('date', isEqualTo: todayKey)
        .get();
    final nofapSnapshot = await firestore.collection('nofap_tracker').doc(uid).get();
    final noteSnapshot = await _notesRef?.doc('${uid}_$todayKey').get();

    final streaks = <String, int>{};
    for (final doc in streakSnapshot.docs) {
      final data = doc.data();
      final moduleId = data['moduleId'] as String? ?? '';
      if (moduleId.isEmpty) {
        continue;
      }
      streaks[moduleId] = (data['currentStreak'] as num?)?.toInt() ?? 0;
    }

    return {
      'streaks': streaks,
      'completedToday': todaySnapshot.docs.map((doc) => doc.data()['moduleId'] as String? ?? '').where((item) => item.isNotEmpty).toList(),
      'nofapStreak': nofapSnapshot.exists ? (nofapSnapshot.data()?['currentStreak'] as num?)?.toInt() ?? 0 : 0,
      'dailyBenefit': noteSnapshot?.data()?['content'] as String? ?? '',
    };
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
