import '../models/user_profile.dart';
import '../models/wellness_snapshot.dart';

class WellnessInsightService {
  const WellnessInsightService();

  WellnessSnapshot buildSnapshot({
    required UserProfile profile,
    required Map<String, double> weeklyCalories,
    required Map<String, int> weeklyWater,
    required Map<String, int> weeklySteps,
    required Map<String, double> weeklySleep,
    required int dailyGoal,
  }) {
    final orderedDays = <String>{
      ...weeklyCalories.keys,
      ...weeklyWater.keys,
      ...weeklySteps.keys,
      ...weeklySleep.keys,
    }.toList()
      ..sort();

    final calorieStreak = _trailingStreak(
      orderedDays,
      (day) {
        final calories = weeklyCalories[day] ?? 0;
        return calories > 0 && dailyGoal > 0 && calories <= dailyGoal;
      },
    );
    final waterStreak = _trailingStreak(
      orderedDays,
      (day) => (weeklyWater[day] ?? 0) >= 8,
    );
    final activeDays = orderedDays.where((day) => (weeklySteps[day] ?? 0) > 0).length;

    final calorieDays = weeklyCalories.values.where((value) => value > 0).toList();
    final sleepDays = weeklySleep.values.where((value) => value > 0).toList();
    final stepDays = weeklySteps.values.where((value) => value > 0).toList();

    final achievements = <WellnessAchievement>[
      if (calorieStreak >= 3)
        WellnessAchievement(
          title: '$calorieStreak দিনের ক্যালরি স্ট্রিক',
          subtitle: 'টানা কয়েকদিন আপনি লক্ষ্যের ভেতরে থেকেছেন।',
          emoji: '🔥',
        ),
      if (waterStreak >= 3)
        WellnessAchievement(
          title: '$waterStreak দিনের পানি স্ট্রিক',
          subtitle: 'হাইড্রেশন ধারাবাহিকভাবে ধরে রেখেছেন।',
          emoji: '💧',
        ),
      if (activeDays >= 4)
        WellnessAchievement(
          title: '$activeDays দিন অ্যাক্টিভ',
          subtitle: 'হাঁটা বা activity নিয়মিত লগ হয়েছে।',
          emoji: '🚶',
        ),
      if (sleepDays.isNotEmpty && (sleepDays.reduce((a, b) => a + b) / sleepDays.length) >= 7)
        const WellnessAchievement(
          title: 'ঘুমের ভারসাম্য ভালো',
          subtitle: 'এই সপ্তাহে গড় ঘুম ৭ ঘণ্টার কাছাকাছি।',
          emoji: '🌙',
        ),
    ];

    final bestDayCalories = calorieDays.isEmpty
        ? null
        : calorieDays.reduce((a, b) {
            final aDiff = (dailyGoal - a).abs();
            final bDiff = (dailyGoal - b).abs();
            return aDiff <= bDiff ? a : b;
          });

    final avgSleepHours = sleepDays.isEmpty ? null : sleepDays.reduce((a, b) => a + b) / sleepDays.length;
    final avgSteps = stepDays.isEmpty ? null : (stepDays.reduce((a, b) => a + b) / stepDays.length).round();

    return WellnessSnapshot(
      calorieStreakDays: calorieStreak,
      waterStreakDays: waterStreak,
      activeDays: activeDays,
      bestDayCalories: bestDayCalories,
      avgSleepHours: avgSleepHours,
      avgSteps: avgSteps,
      achievements: achievements,
      shareText: _buildShareText(
        profile: profile,
        dailyGoal: dailyGoal,
        calorieStreak: calorieStreak,
        waterStreak: waterStreak,
        activeDays: activeDays,
        avgSleepHours: avgSleepHours,
        avgSteps: avgSteps,
      ),
    );
  }

  int _trailingStreak(List<String> orderedDays, bool Function(String day) predicate) {
    if (orderedDays.isEmpty) {
      return 0;
    }
    var streak = 0;
    for (final day in orderedDays.reversed) {
      if (predicate(day)) {
        streak += 1;
      } else if (streak > 0) {
        break;
      }
    }
    return streak;
  }

  String _buildShareText({
    required UserProfile profile,
    required int dailyGoal,
    required int calorieStreak,
    required int waterStreak,
    required int activeDays,
    required double? avgSleepHours,
    required int? avgSteps,
  }) {
    final sleepText = avgSleepHours == null ? '—' : '${avgSleepHours.toStringAsFixed(1)} ঘণ্টা';
    final stepsText = avgSteps == null ? '—' : '$avgSteps';
    return [
      'Sushastho.ai • সাপ্তাহিক রিপোর্ট',
      '${profile.name} এই সপ্তাহে $activeDays দিন active ছিলেন।',
      'ক্যালরি স্ট্রিক: $calorieStreak দিন',
      'পানি স্ট্রিক: $waterStreak দিন',
      'গড় ঘুম: $sleepText',
      'গড় স্টেপ: $stepsText',
      'দৈনিক ক্যালরি লক্ষ্য: $dailyGoal kcal',
    ].join('\n');
  }
}
