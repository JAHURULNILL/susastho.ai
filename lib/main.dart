import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/services/firebase_bootstrap_service.dart';
import 'data/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Render error:\n${details.exceptionAsString()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  };

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

  if (startupError == null) {
    unawaited(FirebaseBootstrapService.ensureSignedIn());
    unawaited(_initializeNotifications());
  }
}

Future<void> _initializeNotifications() async {
  final notifications = NotificationService(FlutterLocalNotificationsPlugin());
  await notifications.initialize();
  await notifications.scheduleDailyReminders();
}
