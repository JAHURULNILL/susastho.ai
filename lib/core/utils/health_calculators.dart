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
    final genderAdjustment = profile.gender == UserGender.male ? 5 : -161;
    final base = (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * profile.age);

    return switch (profile.goal) {
      UserGoal.weightLoss => (base + genderAdjustment - 350).round(),
      UserGoal.weightGain => (base + genderAdjustment + 300).round(),
      UserGoal.maintenance => (base + genderAdjustment).round(),
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
