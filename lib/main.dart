import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/services/firebase_bootstrap_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;

  try {
    await FirebaseBootstrapService.initialize();
  } catch (error) {
    startupError = error;
  }

  runApp(
    ProviderScope(
      child: SushasthoApp(startupError: startupError),
    ),
  );
}
