import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../repositories/health_metrics_repository.dart';
import 'health_sync_service.dart';
import 'local_storage_service.dart';

class ActivityTrackingService {
  ActivityTrackingService({
    required LocalStorageService storage,
    required HealthMetricsRepository healthMetricsRepository,
    required HealthSyncService healthSyncService,
  })  : _storage = storage,
        _healthMetricsRepository = healthMetricsRepository,
        _healthSyncService = healthSyncService;

  final LocalStorageService _storage;
  final HealthMetricsRepository _healthMetricsRepository;
  final HealthSyncService _healthSyncService;

  StreamSubscription<StepCount>? _stepSubscription;
  Timer? _syncTimer;
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
    unawaited(_healthSyncService.syncToday());
    _stepSubscription = Pedometer.stepCountStream.listen(_handleStepEvent);
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_healthSyncService.syncToday());
    });
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
    _syncTimer?.cancel();
    _syncTimer = null;
    _started = false;
  }
}
