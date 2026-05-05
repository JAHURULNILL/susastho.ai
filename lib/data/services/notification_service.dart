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
    'স্বাস্থ্য রিমাইন্ডার',
    channelDescription: 'Sushastho.ai ব্যক্তিগত স্বাস্থ্য রিমাইন্ডার',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _details = NotificationDetails(android: _androidDetails);

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleDailyReminders({int nofapStreak = 0}) async {
    await cancelAll();

    await _schedule(
      id: 1,
      hour: 6,
      minute: 30,
      title: 'শুভ সকাল',
      body: 'এখন ঘুম থেকে উঠে একটু হাঁটাহাঁটি করুন। সকালের হালকা হাঁটা শরীরের জন্য উপকারী।',
    );
    await _schedule(
      id: 2,
      hour: 8,
      minute: 30,
      title: 'সকালের খাবারের সময়',
      body: 'সকালের খাবার খেয়ে নিন। পরে অন্তত ৩০ মিনিট হাঁটলে শরীর আরও ভালো থাকবে।',
    );
    await _schedule(
      id: 3,
      hour: 13,
      minute: 15,
      title: 'দুপুরের খাবারের সময়',
      body: 'দুপুরের খাবার খেয়ে নিন। বেশি দেরি করলে দুর্বল লাগতে পারে।',
    );
    await _schedule(
      id: 4,
      hour: 17,
      minute: 0,
      title: 'বিকেলে একটু হাঁটুন',
      body: 'একটু বাইরে হাঁটুন, প্রকৃতি দেখুন। এটি শরীর আর মানসিক স্বাস্থ্যের জন্য ভালো।',
    );
    await _schedule(
      id: 5,
      hour: 20,
      minute: 30,
      title: 'রাতের খাবারের সময়',
      body: 'রাতের খাবার দেরি না করে খেয়ে নিন। পরে একটু হাঁটলে হজম আর ঘুম দুইটাই ভালো হবে।',
    );
    await _schedule(
      id: 6,
      hour: 23,
      minute: 0,
      title: 'এখন ঘুমানোর সময়',
      body: 'রাত ১১টার দিকে নিয়মিত ঘুমালে শরীরের পুনরুদ্ধার আর হরমোনের ছন্দ ভালো থাকে।',
    );

    await _scheduleWellnessReminders(nofapStreak: nofapStreak);
  }

  Future<void> scheduleContextualReminders({
    required UserProfile profile,
    required AppSettings settings,
    required DailySummary summary,
    StepLogRecord? steps,
    SleepLogRecord? sleep,
    int nofapStreak = 0,
  }) async {
    await cancelAll();

    final totalCalories = summary.consumedMacros.calories.round();
    final waterGlasses = summary.waterGlasses;
    final stepCount = steps?.steps ?? 0;
    final sleepHours = sleep?.hours ?? 0;
    final goal = settings.customCalorieGoal ?? profile.dailyCalorieTarget;

    await _schedule(
      id: 1,
      hour: 6,
      minute: 30,
      title: 'শুভ সকাল, ${profile.name}',
      body: '${profile.name}, এখন ঘুম থেকে উঠে একটু হাঁটাহাঁটি করুন। সকালের হালকা হাঁটা আপনার জন্য উপকারী।',
    );
    await _schedule(
      id: 2,
      hour: 8,
      minute: 30,
      title: '${profile.name}, সকালের খাবারের সময়',
      body: totalCalories > 0
          ? '${profile.name}, আজ কিছু খাবার লগ আছে। তারপরও সকালের খাবার ঠিক সময়ে শেষ করে ৩০ মিনিট হাঁটতে ভুলবেন না।'
          : '${profile.name}, সকালের খাবার খেয়ে নিন। সময় হয়ে গেছে, আর খাওয়ার পরে অবশ্যই ৩০ মিনিট হাঁটবেন।',
    );
    await _schedule(
      id: 3,
      hour: 13,
      minute: 15,
      title: '${profile.name}, দুপুরের খাবার খেয়ে নিন',
      body: totalCalories == 0
          ? '${profile.name}, এখনো কোনো খাবার লগ হয়নি। দুপুরের খাবার আর দেরি না করে খেয়ে নিন।'
          : '${profile.name}, দুপুরের খাবার খেয়ে নিন। বেশি দেরি করবেন না, তাতে শরীরের এনার্জি নষ্ট হতে পারে।',
    );
    await _schedule(
      id: 4,
      hour: 17,
      minute: 0,
      title: 'বিকেলের হাঁটার সময়',
      body: _afternoonBody(
        name: profile.name,
        waterGlasses: waterGlasses,
        stepCount: stepCount,
      ),
    );
    await _schedule(
      id: 5,
      hour: 20,
      minute: 30,
      title: '${profile.name}, রাতের খাবারের সময়',
      body: goal > 0 && totalCalories >= goal
          ? '${profile.name}, আজ ক্যালরি প্রায় পূর্ণ হয়েছে। রাতে হালকা খাবার নিন আর বেশি দেরি করবেন না।'
          : '${profile.name}, রাতের খাবার খেয়ে নিন। হালকা ও সুষম খাবার নিলে ঘুম আর হজম দুইটাই ভালো থাকবে।',
    );
    await _schedule(
      id: 6,
      hour: 23,
      minute: 0,
      title: 'ঘুমানোর সময় হয়েছে',
      body: _sleepBody(
        name: profile.name,
        sleepHours: sleepHours,
        stepCount: stepCount,
      ),
    );

    if (settings.fastingEnabled) {
      final reminderHour = (settings.fastingStartHour + settings.fastingWindowHours) % 24;
      await _schedule(
        id: 7,
        hour: reminderHour,
        minute: 0,
        title: 'ফাস্টিং উইন্ডো আপডেট',
        body: 'আজকের ফাস্টিং সময় শেষ হলে প্রথম খাবার প্রোটিন আর পানি দিয়ে শুরু করুন।',
      );
    }

    await _scheduleWellnessReminders(nofapStreak: nofapStreak);
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  String _afternoonBody({
    required String name,
    required int waterGlasses,
    required int stepCount,
  }) {
    final waterHint = waterGlasses < 4
        ? 'আজ পানি একটু কম হয়েছে, হাঁটার আগে এক গ্লাস পানি খেয়ে নিন। '
        : '';
    final stepHint = stepCount > 0 ? 'আজ এখন পর্যন্ত $stepCount স্টেপ হয়েছে। ' : '';
    return '$name, একটু বাইরে হাঁটুন, প্রকৃতি দেখুন। $stepHint$waterHintএটি মানসিক স্বাস্থ্যের জন্যও উপকারী।';
  }

  String _sleepBody({
    required String name,
    required double sleepHours,
    required int stepCount,
  }) {
    final sleepHint = sleepHours > 0 ? 'গতবার $sleepHours ঘণ্টা ঘুম লগ ছিল। ' : '';
    final stepHint = stepCount > 0 ? 'আজ $stepCount স্টেপ হয়েছে। ' : '';
    return '$name, এখন ঘুমানোর সময়। $stepHint$sleepHintরাত ১১টার দিকে নিয়মিত ঘুমালে পুনরুদ্ধার ভালো হয়।';
  }

  Future<void> _scheduleWellnessReminders({required int nofapStreak}) async {
    await _schedule(
      id: 30,
      hour: 7,
      minute: 30,
      title: '🌬️ সকালের শ্বাস-প্রশ্বাস',
      body: '৫ মিনিটের breathing exercise দিয়ে দিন শুরু করুন।',
    );
    await _schedule(
      id: 31,
      hour: 8,
      minute: 0,
      title: '🚿 ঠান্ডা গোসল',
      body: 'আজকের cold shower করুন। এনার্জি বাড়বে!',
    );
    await _schedule(
      id: 32,
      hour: 10,
      minute: 0,
      title: '💪 কেগেল ব্যায়ামের সময়',
      body: 'আজকের kegel session করুন। মাত্র ৮ মিনিট!',
    );
    await _schedule(
      id: 33,
      hour: 15,
      minute: 0,
      title: '🧘 মেডিটেশনের সময়',
      body: 'একটু থামুন। ১০ মিনিটের mindfulness session করুন।',
    );
    await _schedule(
      id: 34,
      hour: 20,
      minute: 0,
      title: '🔒 আজকের দিন পার করলেন!',
      body: 'No Fap streak: $nofapStreak দিন। চালিয়ে যান! 💪',
    );
    await _schedule(
      id: 35,
      hour: 21,
      minute: 30,
      title: '🌙 ঘুমের রুটিন শুরু',
      body: 'স্ক্রিন বন্ধ করুন। আজকের sleep routine শুরু করুন।',
    );
  }
}
