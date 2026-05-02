import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/food_analysis_result.dart';
import '../../../shared/providers/app_state_provider.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.advice,
    required this.targetMacros,
    required this.consumedMacros,
  });

  final String advice;
  final NutritionMacro targetMacros;
  final NutritionMacro consumedMacros;
}

final homeDashboardProvider = Provider<HomeDashboardData?>((ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  if (profile == null) {
    return null;
  }

  final advice = ref.watch(dailyAdviceServiceProvider).getAdvice(profile);
  final targetCalories = profile.dailyCalorieTarget.toDouble();

  return HomeDashboardData(
    advice: advice,
    targetMacros: NutritionMacro(
      calories: targetCalories,
      protein: profile.weightKg * 1.2,
      carbs: targetCalories * 0.5 / 4,
      fat: targetCalories * 0.25 / 9,
    ),
    consumedMacros: const NutritionMacro(
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
    ),
  );
});
