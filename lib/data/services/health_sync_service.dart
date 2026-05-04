import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../repositories/health_metrics_repository.dart';

class HealthSyncService {
  HealthSyncService(this._repository) : _health = Health();

  final HealthMetricsRepository _repository;
  final Health _health;

  Future<bool> syncToday() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = now;

    if (Platform.isAndroid) {
      await Permission.activityRecognition.request();
    }

    final types = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.SLEEP_ASLEEP,
    ];
    final permissions = <HealthDataAccess>[
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    final granted = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );
    if (!granted) {
      return false;
    }

    final steps = await _health.getTotalStepsInInterval(start, end) ?? 0;

    final points = await _health.getHealthDataFromTypes(
      types: types,
      startTime: start,
      endTime: end,
    );
    double sleepHours = 0;
    double activeCalories = 0;
    for (final point in points) {
      if (point.type == HealthDataType.SLEEP_ASLEEP && point.value is NumericHealthValue) {
        sleepHours += (point.value as NumericHealthValue).numericValue.toDouble() / 60;
      }
      if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED && point.value is NumericHealthValue) {
        activeCalories += (point.value as NumericHealthValue).numericValue.toDouble();
      }
    }

    if (steps > 0 || activeCalories > 0) {
      await _repository.saveSteps(
        steps,
        activeCalories: activeCalories > 0 ? activeCalories : null,
      );
    }

    if (sleepHours > 0) {
      await _repository.saveSleep(
        hours: sleepHours.clamp(0, 24),
        quality: sleepHours >= 7.5
            ? 'good'
            : sleepHours >= 6
                ? 'fair'
                : 'poor',
      );
    }

    return steps > 0 || sleepHours > 0 || activeCalories > 0;
  }
}
