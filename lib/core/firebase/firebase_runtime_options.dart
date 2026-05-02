import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_strings.dart';

class FirebaseRuntimeOptions {
  const FirebaseRuntimeOptions._();

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Sushastho.ai বর্তমানে Android এবং iOS Firebase setup-এর জন্য configured.',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _apiKey,
        appId: _androidAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _apiKey,
        appId: _iosAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
      );

  static String get _apiKey => const String.fromEnvironment(AppStrings.firebaseApiKeyEnv);
  static String get _projectId => const String.fromEnvironment(AppStrings.firebaseProjectIdEnv);
  static String get _messagingSenderId => const String.fromEnvironment(
        AppStrings.firebaseMessagingSenderIdEnv,
      );
  static String get _storageBucket => const String.fromEnvironment(AppStrings.firebaseStorageBucketEnv);
  static String get _androidAppId => const String.fromEnvironment(AppStrings.firebaseAndroidAppIdEnv);
  static String get _iosAppId => const String.fromEnvironment(AppStrings.firebaseIosAppIdEnv);
  static String get _iosBundleId => const String.fromEnvironment(AppStrings.firebaseIosBundleIdEnv);

  static void validate() {
    _require(_apiKey, AppStrings.firebaseApiKeyEnv);
    _require(_projectId, AppStrings.firebaseProjectIdEnv);
    _require(_messagingSenderId, AppStrings.firebaseMessagingSenderIdEnv);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _require(_androidAppId, AppStrings.firebaseAndroidAppIdEnv);
      case TargetPlatform.iOS:
        _require(_iosAppId, AppStrings.firebaseIosAppIdEnv);
      default:
        throw UnsupportedError(
          'Sushastho.ai বর্তমানে Android এবং iOS Firebase setup-এর জন্য configured.',
        );
    }
  }

  static void _require(String value, String key) {
    if (value.trim().isEmpty) {
      throw StateError('$key is missing');
    }
  }
}
