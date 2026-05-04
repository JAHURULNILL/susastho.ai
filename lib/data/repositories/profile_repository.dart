import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../services/local_storage_service.dart';

class ProfileRepository {
  ProfileRepository(
    this._storage, {
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final LocalStorageService _storage;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  DocumentReference<Map<String, dynamic>>? get _profileRef {
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return null;
    }
    return firestore.collection('users').doc(uid);
  }

  String? get _cacheKey {
    final uid = _auth?.currentUser?.uid;
    if (uid == null) {
      return null;
    }
    return 'user_profile_$uid';
  }

  Future<UserProfile?> loadProfile() async {
    final ref = _profileRef;
    if (ref == null) {
      return null;
    }

    try {
      final snapshot = await ref.get();
      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      final profile = UserProfile.fromJson(data);
      final key = _cacheKey;
      if (key != null) {
        await _storage.saveJson(key, profile.toJson());
      }
      return profile;
    } catch (_) {
      final key = _cacheKey;
      if (key == null) {
        return null;
      }
      final cached = await _storage.readJson(key);
      return cached == null ? null : UserProfile.fromJson(cached);
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final key = _cacheKey;
    if (key != null) {
      await _storage.saveJson(key, profile.toJson());
    }

    final ref = _profileRef;
    if (ref == null) {
      return;
    }

    final bmr = (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * profile.age) + 5;
    final weekKey = _formatDate(_startOfWeek(DateTime.now()));
    final notesRef = ref.collection('doctor_notes');
    final mealPlanRef = ref.collection('meal_plans').doc(weekKey);
    final weightRef = ref.collection('weight_history').doc();

    final batch = _firestore?.batch();

    if (batch != null) {
      batch.set(
        ref,
        {
          ...profile.toJson(),
          'dailyCalorieTarget': profile.dailyCalorieTarget,
          'dailyStepTarget': profile.dailyStepTarget,
          'bmr': bmr.round(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        weightRef,
        {
          'weightKg': profile.weightKg,
          'dateKey': _formatDate(DateTime.now()),
          'recordedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      final activeNotes = await notesRef.get();
      for (final note in activeNotes.docs) {
        batch.update(note.reference, {'expiresAt': DateTime.now().toIso8601String()});
      }

      batch.delete(mealPlanRef);
      await batch.commit();
      return;
    }

    await ref.set(
      {
        ...profile.toJson(),
        'dailyCalorieTarget': profile.dailyCalorieTarget,
        'dailyStepTarget': profile.dailyStepTarget,
        'bmr': bmr.round(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> clearProfile() async {
    final key = _cacheKey;
    if (key != null) {
      await _storage.remove(key);
    }

    final ref = _profileRef;
    if (ref == null) {
      return;
    }

    await ref.delete();
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
