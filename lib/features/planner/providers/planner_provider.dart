import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/weekly_plan.dart';
import '../../../shared/providers/app_state_provider.dart';

final weeklyMealPlanProvider = FutureProvider<WeeklyMealPlan?>((ref) async {
  final profile = ref.watch(userProfileProvider).asData?.value;
  if (profile == null) {
    return null;
  }

  return ref.read(plannerRepositoryProvider).getOrGenerateWeeklyMealPlan(profile);
});

final weeklyCaloriesProvider = FutureProvider<Map<String, double>>((ref) async {
  return ref.read(dailySummaryRepositoryProvider).loadCurrentWeekCalories();
});
