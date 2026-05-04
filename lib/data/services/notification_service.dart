import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import '../models/daily_summary.dart';
import '../models/health_metrics.dart';
import '../models/user_profile.dart';

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

  Future<void> scheduleContextualReminders({
    required UserProfile profile,
    required AppSettings settings,
    required DailySummary summary,
    StepLogRecord? steps,
    SleepLogRecord? sleep,
  }) async {
    await cancelAll();

    final totalCalories = summary.consumedMacros.calories.round();
    final stepCount = steps?.steps ?? 0;
    final sleepHours = sleep?.hours ?? 0;
    final morningTitle = totalCalories == 0
        ? 'শুভ সকাল, ${profile.name}'
        : 'আজকের শুরু ভালো হয়েছে';
    final morningBody = totalCalories == 0
        ? 'নাশতা লগ করলে আজকের পরামর্শ আর ক্যালরি ট্র্যাকিং সঙ্গে সঙ্গে শুরু হবে।'
        : 'সকালের খাবার already লগ আছে। দুপুরের আগে এক গ্লাস পানি খেতে ভুলবেন না।';
    final lunchBody = totalCalories == 0
        ? 'দুপুরের আগে এখনো কোনো খাবার লগ হয়নি। আজকের প্রথম মিল লিখে বা স্ক্যান করে রাখুন।'
        : 'এখন পর্যন্ত $totalCalories kcal হয়েছে। দুপুরের মিল যোগ করলে AI আরও নির্ভুলভাবে গাইড করতে পারবে।';
    final waterBody = summary.waterGlasses >= 4
        ? 'আজ ${summary.waterGlasses}/৮ গ্লাস পানি হয়েছে। বিকেলে শরীর hydrated রাখতে আরেক গ্লাস নিন।'
        : 'এখনো ${summary.waterGlasses}/৮ গ্লাস পানি হয়েছে। বিকেলের মধ্যে অন্তত ৪ গ্লাসে নেয়ার চেষ্টা করুন।';
    final nightBody = _nightReviewBody(
      profile: profile,
      settings: settings,
      totalCalories: totalCalories,
      stepCount: stepCount,
      sleepHours: sleepHours,
    );

    await _schedule(id: 1, hour: 8, minute: 0, title: morningTitle, body: morningBody);
    await _schedule(id: 2, hour: 13, minute: 0, title: 'দুপুরের আপডেট', body: lunchBody);
    await _schedule(id: 3, hour: 16, minute: 0, title: 'পানি পান রিমাইন্ডার', body: waterBody);
    await _schedule(id: 4, hour: 20, minute: 0, title: 'রাতের স্বাস্থ্য পর্যালোচনা', body: nightBody);

    if (settings.fastingEnabled) {
      final reminderHour = (settings.fastingStartHour + settings.fastingWindowHours) % 24;
      await _schedule(
        id: 5,
        hour: reminderHour,
        minute: 0,
        title: 'ফাস্টিং উইন্ডো আপডেট',
        body: 'আজকের fasting window শেষ হলে প্রথম meal-এ প্রোটিন আর পানি দিয়ে শুরু করুন।',
      );
    }
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

  String _nightReviewBody({
    required UserProfile profile,
    required AppSettings settings,
    required int totalCalories,
    required int stepCount,
    required double sleepHours,
  }) {
    final goal = settings.customCalorieGoal ?? profile.dailyCalorieTarget;
    if (goal > 0 && totalCalories == 0) {
      return 'আজ এখনো কোনো মিল লগ হয়নি। রাতের খাবার স্ক্যান করলে কালকের ডাক্তারের নোট আরও ভালো হবে।';
    }
    if (goal > 0 && totalCalories > goal) {
      return 'আজ লক্ষ্য থেকে কিছুটা বেশি হয়েছে। ঘুমের আগে হালকা হাঁটা আর পানি শরীরকে balance করতে সাহায্য করবে।';
    }
    if (stepCount > 0 && sleepHours == 0) {
      return 'আজ $stepCount স্টেপ হয়েছে। ঘুমানোর আগে আজকের sleep time-ও যোগ করলে recovery insight আরও ভালো হবে।';
    }
    return 'আজকের data বেশ ভালো। রাতের আগে পানি, হালকা stretching আর নিয়মিত ঘুম আপনার ধারাবাহিকতা ধরে রাখবে।';
  }
}
