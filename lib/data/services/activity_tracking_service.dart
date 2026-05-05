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
    final stateKey = 'step_state_$todayKey';
    final cached = await _storage.readJson(stateKey);
    final currentSteps = event.steps;

    int baseline = 0;
    int savedSteps = 0;

    if (cached == null) {
      baseline = currentSteps;
      await _storage.saveJson(stateKey, {'baseline': baseline, 'savedSteps': 0});
    } else {
      baseline = (cached['baseline'] as num?)?.toInt() ?? currentSteps;
      savedSteps = (cached['savedSteps'] as num?)?.toInt() ?? 0;
    }

    if (currentSteps < baseline) {
      // Device was rebooted. Pedometers reset to 0.
      // We add whatever we had calculated to savedSteps and reset baseline to 0.
      final previousTotal = savedSteps;
      baseline = currentSteps;
      savedSteps = previousTotal;
      await _storage.saveJson(stateKey, {'baseline': baseline, 'savedSteps': savedSteps});
    }

    // currentSteps since boot - baseline + steps from before boot today
    final todaySteps = (currentSteps - baseline + savedSteps).clamp(0, 200000);
    
    // Periodically update the state to prevent losing data if app crashes
    if (todaySteps % 10 == 0) {
        await _storage.saveJson(stateKey, {'baseline': baseline, 'savedSteps': savedSteps});
    }

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
