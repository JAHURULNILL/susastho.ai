import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/daily_advice_service.dart';
import '../../data/services/local_storage_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferencesAsync>((ref) {
  return SharedPreferencesAsync();
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (Firebase.apps.isEmpty) {
    return null;
  }

  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (Firebase.apps.isEmpty) {
    return null;
  }

  return FirebaseFirestore.instance;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return ProfileRepository(
    storage,
    auth: auth,
    firestore: firestore,
  );
});

final dailyAdviceServiceProvider = Provider<DailyAdviceService>((ref) {
  return const DailyAdviceService();
});

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final repository = ref.read(profileRepositoryProvider);
    return repository.loadProfile();
  }

  Future<void> save(UserProfile profile) async {
    state = const AsyncLoading();
    final repository = ref.read(profileRepositoryProvider);
    await repository.saveProfile(profile);
    state = AsyncData(profile);
  }

  Future<void> clear() async {
    state = const AsyncLoading();
    final repository = ref.read(profileRepositoryProvider);
    await repository.clearProfile();
    state = const AsyncData(null);
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
