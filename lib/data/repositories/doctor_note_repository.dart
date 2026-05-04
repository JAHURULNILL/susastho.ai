import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_summary.dart';
import '../models/doctor_note.dart';
import '../models/user_profile.dart';
import '../models/weekly_plan.dart';
import '../services/ai_backend_service.dart';
import '../services/local_storage_service.dart';
import 'daily_summary_repository.dart';
import 'health_metrics_repository.dart';

class DoctorNoteRepository {
  DoctorNoteRepository({
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

  static const Duration noteTtl = Duration(minutes: 10);

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final AiBackendService _aiBackendService;
  final LocalStorageService _storage;
  final DailySummaryRepository _dailySummaryRepository;
  final HealthMetricsRepository _healthMetricsRepository;

  CollectionReference<Map<String, dynamic>>? get _notesRef {
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return null;
    }
    return firestore.collection('users').doc(uid).collection('doctor_notes');
  }

  String? get _cacheKey {
    final uid = _auth?.currentUser?.uid;
    return uid == null ? null : 'doctor_note_$uid';
  }

  Future<DoctorNoteRecord?> getOrGenerate({
    required UserProfile profile,
    required DailySummary summary,
    required List<WeeklyExerciseItem> exercises,
  }) async {
    final ref = _notesRef;
    final cacheKey = _cacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJson(cacheKey);
      if (cached != null) {
        final record = DoctorNoteRecord.fromJson('cached', cached);
        if (!record.isExpired) {
          return record;
        }
      }
    }

    if (ref == null) {
      return null;
    }

    final now = DateTime.now();
    final activeSnapshot = await ref
        .where('expiresAt', isGreaterThan: now.toIso8601String())
        .orderBy('expiresAt', descending: true)
        .limit(1)
        .get();

    if (activeSnapshot.docs.isNotEmpty) {
      final record = DoctorNoteRecord.fromJson(
        activeSnapshot.docs.first.id,
        activeSnapshot.docs.first.data(),
      );
      if (cacheKey != null) {
        await _storage.saveJson(cacheKey, record.toJson());
      }
      return record;
    }

    final recentSnapshot = await ref.orderBy('generatedAt', descending: true).limit(5).get();
    final recentCategories = recentSnapshot.docs
        .map((doc) => doc.data()['category'] as String?)
        .whereType<String>()
        .toList();

    final generated = await _aiBackendService.generateDoctorNote(
      profile: profile,
      summary: summary,
      exercises: exercises,
      recentCategories: recentCategories,
      historicalContext: await _historicalContext(),
    );

    final expiresAt = now.add(noteTtl);
    final doc = ref.doc();
    final record = DoctorNoteRecord(
      id: doc.id,
      content: generated.content,
      category: generated.category,
      generatedAt: now,
      expiresAt: expiresAt,
      contextSnapshot: generated.contextSnapshot,
    );

    await doc.set(record.toJson());
    if (cacheKey != null) {
      await _storage.saveJson(cacheKey, record.toJson());
    }
    return record;
  }

  Future<void> expireAll() async {
    final cacheKey = _cacheKey;
    if (cacheKey != null) {
      await _storage.remove(cacheKey);
    }

    final ref = _notesRef;
    if (ref == null) {
      return;
    }

    final active = await ref.get();
    final batch = _firestore!.batch();
    for (final doc in active.docs) {
      batch.update(doc.reference, {'expiresAt': DateTime.now().toIso8601String()});
    }
    await batch.commit();
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
