import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../repositories/health_metrics_repository.dart';
import 'local_storage_service.dart';

class ActivityTrackingService {
  ActivityTrackingService({
    required LocalStorageService storage,
    required HealthMetricsRepository healthMetricsRepository,
  })  : _storage = storage,
        _healthMetricsRepository = healthMetricsRepository;

  final LocalStorageService _storage;
  final HealthMetricsRepository _healthMetricsRepository;

  StreamSubscription<StepCount>? _stepSubscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) {
      return;
    }

    final permission = await Permission.activityRecognition.request();
    if (!permission.isGranted) {
      return;
    }

    _started = true;
    _stepSubscription = Pedometer.stepCountStream.listen(_handleStepEvent);
  }

  Future<void> _handleStepEvent(StepCount event) async {
    final todayKey = _dateKey(DateTime.now());
    final baselineCacheKey = 'step_baseline_$todayKey';
    final cached = await _storage.readJson(baselineCacheKey);
    final currentSteps = event.steps;

    int baseline;
    if (cached == null) {
      baseline = currentSteps;
      await _storage.saveJson(baselineCacheKey, {'baseline': baseline});
    } else {
      baseline = (cached['baseline'] as num?)?.toInt() ?? currentSteps;
    }

    final todaySteps = (currentSteps - baseline).clamp(0, 200000);
    await _healthMetricsRepository.saveSteps(todaySteps);
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> dispose() async {
    await _stepSubscription?.cancel();
    _stepSubscription = null;
    _started = false;
  }
}
