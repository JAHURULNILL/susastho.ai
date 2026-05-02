import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/firebase/firebase_runtime_options.dart';

class FirebaseBootstrapService {
  const FirebaseBootstrapService._();

  static Future<void> initialize() async {
    FirebaseRuntimeOptions.validate();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseRuntimeOptions.currentPlatform,
      );
    }

    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }
}
