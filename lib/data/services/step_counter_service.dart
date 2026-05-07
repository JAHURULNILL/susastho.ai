import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level callback — this runs in an isolate when the foreground service starts.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(StepCounterTaskHandler());
}

/// The actual handler that runs in the foreground service isolate.
class StepCounterTaskHandler extends TaskHandler {
  StreamSubscription<StepCount>? _subscription;
  int _todaySteps = 0;
  int _baseline = 0;
  int _savedSteps = 0;
  String _todayKey = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    dev.log('[StepService] onStart');
    _todayKey = _dateKey(DateTime.now());

    // Load saved state
    final prefs = SharedPreferencesAsync();
    final stateKey = 'fg_step_state_$_todayKey';
    final saved = await prefs.getString(stateKey);
    if (saved != null) {
      final parts = saved.split(',');
      if (parts.length == 3) {
        _baseline = int.tryParse(parts[0]) ?? 0;
        _savedSteps = int.tryParse(parts[1]) ?? 0;
        _todaySteps = int.tryParse(parts[2]) ?? 0;
      }
    }

    // Listen to pedometer
    _subscription = Pedometer.stepCountStream.listen(
      _onStep,
      onError: (e) => dev.log('[StepService] Pedometer error: $e'),
    );
  }

  void _onStep(StepCount event) async {
    final now = DateTime.now();
    final newDayKey = _dateKey(now);

    // Day changed — reset
    if (newDayKey != _todayKey) {
      _todayKey = newDayKey;
      _baseline = event.steps;
      _savedSteps = 0;
      _todaySteps = 0;
    }

    final currentSteps = event.steps;

    if (_baseline == 0) {
      _baseline = currentSteps;
    }

    // Handle device reboot (steps reset to lower value)
    if (currentSteps < _baseline) {
      _savedSteps += (_todaySteps > 0 ? _todaySteps : 0);
      _baseline = currentSteps;
    }

    _todaySteps = (currentSteps - _baseline + _savedSteps).clamp(0, 200000);

    // Update the notification
    FlutterForegroundTask.updateService(
      notificationTitle: '🚶 আজ $_todaySteps স্টেপ হয়েছে',
      notificationText: 'হাঁটতে থাকুন, সুস্থ থাকুন!',
    );

    // Send data to main isolate (UI) 
    FlutterForegroundTask.sendDataToMain({'steps': _todaySteps});

    // Save state on every single step event to ensure 100% absolute background persistence
    await _saveState();
  }

  Future<void> _saveState() async {
    final prefs = SharedPreferencesAsync();
    final stateKey = 'fg_step_state_$_todayKey';
    await prefs.setString(stateKey, '$_baseline,$_savedSteps,$_todaySteps');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // Called every 5 minutes — save state and update notification
    final now = DateTime.now();
    final newDayKey = _dateKey(now);

    if (newDayKey != _todayKey) {
      _todayKey = newDayKey;
      _baseline = 0;
      _savedSteps = 0;
      _todaySteps = 0;
    }

    FlutterForegroundTask.updateService(
      notificationTitle: '🚶 আজ $_todaySteps স্টেপ হয়েছে',
      notificationText: 'হাঁটতে থাকুন, সুস্থ থাকুন!',
    );

    await _saveState();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    dev.log('[StepService] onDestroy');
    await _saveState();
    await _subscription?.cancel();
    _subscription = null;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

/// Helper class to initialize and manage the foreground step counting service.
class StepCounterForegroundService {
  static Future<void> init() async {
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'step_counter_channel',
        channelName: 'স্টেপ কাউন্টার',
        channelDescription: 'ব্যাকগ্রাউন্ডে আপনার হাঁটা ট্র্যাক করছে',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        playSound: false,
        enableVibration: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(300000), // every 5 min
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: 200,
      notificationTitle: '🚶 স্টেপ কাউন্ট চালু আছে',
      notificationText: 'হাঁটতে থাকুন, সুস্থ থাকুন!',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  /// Load current step count from shared preferences (for when UI starts fresh)
  static Future<int> loadTodaySteps() async {
    final prefs = SharedPreferencesAsync();
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final todayKey = '${now.year}-$month-$day';
    final stateKey = 'fg_step_state_$todayKey';
    final saved = await prefs.getString(stateKey);
    if (saved != null) {
      final parts = saved.split(',');
      if (parts.length == 3) {
        return int.tryParse(parts[2]) ?? 0;
      }
    }
    return 0;
  }
}
