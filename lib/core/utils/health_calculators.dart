import '../../data/models/user_profile.dart';

class HealthCalculators {
  const HealthCalculators._();

  static double bmi(UserProfile profile) {
    final heightInMeter = profile.heightCm / 100;
    if (heightInMeter == 0) {
      return 0;
    }
    return profile.weightKg / (heightInMeter * heightInMeter);
  }

  static int dailyCalorieTarget(UserProfile profile) {
    final base = (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * profile.age);

    return switch (profile.goal) {
      UserGoal.weightLoss => (base + 5 - 350).round(),
      UserGoal.weightGain => (base + 5 + 300).round(),
      UserGoal.maintenance => (base + 5).round(),
    };
  }

  static int dailyStepTarget(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.diabetes)) {
      return 7000;
    }
    if (profile.conditions.contains(HealthCondition.obesity) ||
        profile.conditions.contains(HealthCondition.bellyFat)) {
      return 8000;
    }
    return 5000;
  }
}
