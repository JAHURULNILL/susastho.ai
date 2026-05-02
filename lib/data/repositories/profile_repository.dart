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

  static const String _profileKey = 'user_profile';
  final LocalStorageService _storage;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  DocumentReference<Map<String, dynamic>>? get _profileRef {
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return null;
    }

    return firestore.collection('users').doc(uid).collection('private').doc('profile');
  }

  Future<UserProfile?> loadProfile() async {
    final json = await _storage.readJson(_profileKey);
    if (json != null) {
      return UserProfile.fromJson(json);
    }

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
      await _storage.saveJson(_profileKey, profile.toJson());
      return profile;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _storage.saveJson(_profileKey, profile.toJson());

    final ref = _profileRef;
    if (ref == null) {
      return;
    }

    try {
      await ref.set(
        {
          ...profile.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Local save remains available if cloud sync fails temporarily.
    }
  }

  Future<void> clearProfile() async {
    await _storage.remove(_profileKey);

    final ref = _profileRef;
    if (ref == null) {
      return;
    }

    try {
      await ref.delete();
    } catch (_) {
      // Ignore cloud cleanup failures and keep the local flow responsive.
    }
  }
}
