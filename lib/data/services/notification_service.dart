import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _androidDetails = AndroidNotificationDetails(
    'health_reminders',
    'Health Reminders',
    channelDescription: 'Sushastho.ai reminders for meals and water',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _details = NotificationDetails(android: _androidDetails);

  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminders() async {
    await cancelAll();
    await _schedule(
      id: 1,
      hour: 8,
      minute: 0,
      title: 'সকালের খাবার লগ করুন 🌅',
      body: 'আজকের নাস্তা স্ক্যান বা লিখে লগ করুন।',
    );
    await _schedule(
      id: 2,
      hour: 13,
      minute: 0,
      title: 'দুপুরের খাবার স্ক্যান করুন ☀️',
      body: 'দুপুরের খাবার যোগ করলে dashboard আরও নির্ভুল হবে।',
    );
    await _schedule(
      id: 3,
      hour: 16,
      minute: 0,
      title: 'পানি পান করেছেন? 💧',
      body: 'আজকের পানির লক্ষ্য পূরণ হয়েছে কি না দেখে নিন।',
    );
    await _schedule(
      id: 4,
      hour: 20,
      minute: 0,
      title: 'আজকের লক্ষ্য কতটুকু পূরণ হলো? 📊',
      body: 'রাতের আগে আজকের ক্যালরি ও মিল summary দেখে নিন।',
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _schedule({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
