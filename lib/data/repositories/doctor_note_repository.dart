import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_summary.dart';
import '../models/doctor_note.dart';
import '../models/user_profile.dart';
import '../models/weekly_plan.dart';
import '../services/ai_backend_service.dart';

class DoctorNoteRepository {
  DoctorNoteRepository({
    required FirebaseAuth? auth,
    required FirebaseFirestore? firestore,
    required AiBackendService aiBackendService,
  })  : _auth = auth,
        _firestore = firestore,
        _aiBackendService = aiBackendService;

  static const Duration noteTtl = Duration(minutes: 45);

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final AiBackendService _aiBackendService;

  CollectionReference<Map<String, dynamic>>? get _notesRef {
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return null;
    }
    return firestore.collection('users').doc(uid).collection('doctor_notes');
  }

  Future<DoctorNoteRecord?> getOrGenerate({
    required UserProfile profile,
    required DailySummary summary,
    required List<WeeklyExerciseItem> exercises,
  }) async {
    final ref = _notesRef;
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
      return DoctorNoteRecord.fromJson(
        activeSnapshot.docs.first.id,
        activeSnapshot.docs.first.data(),
      );
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
    return record;
  }

  Future<void> expireAll() async {
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
}
