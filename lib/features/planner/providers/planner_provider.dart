import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wellness_routine.dart';
import '../../../data/models/weekly_plan.dart';
import '../../../shared/providers/app_state_provider.dart';

final weeklyMealPlanBootstrapProvider = FutureProvider<void>((ref) async {
  final profile = ref.watch(userProfileProvider).asData?.value;
  if (profile == null) {
    return;
  }

  try {
    await ref.read(plannerRepositoryProvider).ensureCurrentWeekMealPlan(profile);
  } catch (_) {}
});

final weeklyMealPlanProvider = StreamProvider<WeeklyMealPlan?>((ref) {
  ref.watch(weeklyMealPlanBootstrapProvider);
  return ref.watch(plannerRepositoryProvider).watchCurrentWeekMealPlan();
});

final weeklyCaloriesProvider = FutureProvider<Map<String, double>>((ref) async {
  return ref.watch(dailySummaryRepositoryProvider).loadCurrentWeekCalories();
});

class WellnessRoutineNotifier extends AsyncNotifier<WellnessRoutinePlan?> {
  @override
  Future<WellnessRoutinePlan?> build() async {
    final profile = ref.watch(userProfileProvider).asData?.value;
    if (profile == null) {
      return null;
    }
    return ref.watch(wellnessRoutineRepositoryProvider).loadToday(profile);
  }

  Future<void> toggle(WellnessRoutineType type) async {
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) {
      return;
    }
    final updated = await ref.read(wellnessRoutineRepositoryProvider).toggleTask(
          profile: profile,
          type: type,
        );
    state = AsyncData(updated);
  }
}

final wellnessRoutineProvider =
    AsyncNotifierProvider<WellnessRoutineNotifier, WellnessRoutinePlan?>(
  WellnessRoutineNotifier.new,
);
