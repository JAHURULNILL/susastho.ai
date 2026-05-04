import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrapService {
  const FirebaseBootstrapService._();

  static Future<void>? _signInFuture;

  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  static Future<void> ensureSignedIn() {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      return Future.value();
    }

    final inFlight = _signInFuture;
    if (inFlight != null) {
      return inFlight;
    }

    _signInFuture = auth.signInAnonymously().timeout(const Duration(seconds: 8)).then((_) {
      _signInFuture = null;
    }).catchError((_) {
      _signInFuture = null;
    });

    return _signInFuture!;
  }
}
