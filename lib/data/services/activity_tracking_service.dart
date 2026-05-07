import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import '../repositories/health_metrics_repository.dart';
import 'step_counter_service.dart';

class ActivityTrackingService {
  ActivityTrackingService({
    required HealthMetricsRepository healthMetricsRepository,
  }) : _healthMetricsRepository = healthMetricsRepository;

  final HealthMetricsRepository _healthMetricsRepository;

  bool _started = false;
  Timer? _pollTimer;

  Future<void> start() async {
    if (_started) {
      return;
    }

    await Permission.notification.request();
    final permission = await Permission.activityRecognition.request();
    if (!permission.isGranted) {
      dev.log('[ActivityTracking] Activity recognition permission denied');
      return;
    }

    _started = true;

    // Initialize and start foreground service
    await StepCounterForegroundService.init();
    await StepCounterForegroundService.start();

    // Listen for step data from the foreground service isolate
    FlutterForegroundTask.addTaskDataCallback(_onReceiveData);

    // Also load the current saved steps immediately
    final currentSteps = await StepCounterForegroundService.loadTodaySteps();
    if (currentSteps > 0) {
      await _healthMetricsRepository.saveSteps(currentSteps);
    }

    // Poll saved steps every 15 seconds as a reliable fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final steps = await StepCounterForegroundService.loadTodaySteps();
        if (steps > 0) {
          await _healthMetricsRepository.saveSteps(steps);
        }
      } catch (e) {
        dev.log('[ActivityTracking] Poll error: $e');
      }
    });
  }

  void _onReceiveData(Object data) async {
    if (data is Map<String, dynamic>) {
      final steps = (data['steps'] as num?)?.toInt() ?? 0;
      if (steps > 0) {
        try {
          await _healthMetricsRepository.saveSteps(steps);
        } catch (e) {
          dev.log('[ActivityTracking] Save steps error: $e');
        }
      }
    }
  }

  Future<void> dispose() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveData);
    _started = false;
    // Don't stop the foreground service — let it keep counting
  }
}
