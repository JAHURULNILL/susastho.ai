import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_settings.dart';
import '../../../data/models/daily_summary.dart';
import '../../../data/models/food_analysis_result.dart';
import '../../../data/services/daily_advice_service.dart';
import '../../../shared/providers/app_state_provider.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.advice,
    required this.targetMacros,
    required this.consumedMacros,
    required this.summary,
  });

  final HourlyAdvice advice;
  final NutritionMacro targetMacros;
  final NutritionMacro consumedMacros;
  final DailySummary summary;

  int get remainingCalories => (targetMacros.calories - consumedMacros.calories).round().clamp(0, 99999);
}

final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

class DailySummaryNotifier extends AsyncNotifier<DailySummary> {
  @override
  Future<DailySummary> build() async {
    final repository = ref.read(dailySummaryRepositoryProvider);
    return repository.loadToday();
  }

  Future<void> addMeal(FoodAnalysisResult result, {String? imagePath}) async {
    final current = state.value ?? await build();
    final updatedMeals = [
      MealLogEntry.fromAnalysis(result, imagePath: imagePath),
      ...current.meals,
    ];
    final updated = current.copyWith(meals: updatedMeals);
    state = AsyncData(updated);
    await ref.read(dailySummaryRepositoryProvider).save(updated);
  }

  Future<void> setWaterCount(int glasses) async {
    final current = state.value ?? await build();
    final updated = current.copyWith(waterGlasses: glasses.clamp(0, 8));
    state = AsyncData(updated);
    await ref.read(dailySummaryRepositoryProvider).save(updated);
  }
}

final dailySummaryProvider = AsyncNotifierProvider<DailySummaryNotifier, DailySummary>(
  DailySummaryNotifier.new,
);

final homeDashboardProvider = Provider<HomeDashboardData?>((ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  final summary = ref.watch(dailySummaryProvider).asData?.value;
  final settings = ref.watch(appSettingsProvider).asData?.value ?? const AppSettings();
  final now = ref.watch(clockProvider).asData?.value ?? DateTime.now();
  if (profile == null || summary == null) {
    return null;
  }

  final advice = ref.watch(dailyAdviceServiceProvider).getAdvice(
        profile,
        summary: summary,
        now: now,
      );
  final targetCalories = (settings.customCalorieGoal ?? profile.dailyCalorieTarget).toDouble();

  return HomeDashboardData(
    advice: advice,
    summary: summary,
    targetMacros: NutritionMacro(
      calories: targetCalories,
      protein: profile.weightKg * 1.5,
      carbs: targetCalories * 0.5 / 4,
      fat: targetCalories * 0.25 / 9,
    ),
    consumedMacros: summary.consumedMacros,
  );
});
