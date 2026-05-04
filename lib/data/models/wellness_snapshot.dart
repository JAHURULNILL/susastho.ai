class WellnessAchievement {
  const WellnessAchievement({
    required this.title,
    required this.subtitle,
    required this.emoji,
  });

  final String title;
  final String subtitle;
  final String emoji;
}

class WellnessSnapshot {
  const WellnessSnapshot({
    required this.calorieStreakDays,
    required this.waterStreakDays,
    required this.activeDays,
    required this.bestDayCalories,
    required this.avgSleepHours,
    required this.avgSteps,
    required this.achievements,
    required this.shareText,
  });

  final int calorieStreakDays;
  final int waterStreakDays;
  final int activeDays;
  final double? bestDayCalories;
  final double? avgSleepHours;
  final int? avgSteps;
  final List<WellnessAchievement> achievements;
  final String shareText;
}
