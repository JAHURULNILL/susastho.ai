import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/services/firebase_bootstrap_service.dart';
import 'data/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;

  try {
    await FirebaseBootstrapService.initialize();
    final notifications = NotificationService(FlutterLocalNotificationsPlugin());
    await notifications.initialize();
    await notifications.scheduleDailyReminders();
  } catch (error) {
    startupError = error;
  }

  runApp(
    ProviderScope(
      child: SushasthoApp(startupError: startupError),
    ),
  );
}
