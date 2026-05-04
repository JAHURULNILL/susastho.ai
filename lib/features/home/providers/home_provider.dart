import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_settings.dart';
import '../../../data/models/daily_summary.dart';
import '../../../data/models/doctor_note.dart';
import '../../../data/models/food_analysis_result.dart';
import '../../../data/models/weekly_plan.dart';
import '../../../shared/providers/app_state_provider.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.doctorNote,
    required this.targetMacros,
    required this.consumedMacros,
    required this.summary,
    required this.exerciseLogs,
  });

  final DoctorNoteRecord? doctorNote;
  final NutritionMacro targetMacros;
  final NutritionMacro consumedMacros;
  final DailySummary summary;
  final List<WeeklyExerciseItem> exerciseLogs;

  double get burnedCalories => exerciseLogs
      .where((item) => item.completed)
      .fold<double>(0, (sum, item) => sum + item.caloriesBurned);

  int get netCalories => (consumedMacros.calories - burnedCalories).round();
  int get remainingCalories => (targetMacros.calories - netCalories).round();
}

class DailySummaryNotifier extends AsyncNotifier<DailySummary> {
  StreamSubscription<List<MealLogEntry>>? _mealsSubscription;
  StreamSubscription<int>? _waterSubscription;

  List<MealLogEntry> _meals = const [];
  int _water = 0;
  String _dateKey = '';

  @override
  Future<DailySummary> build() async {
    final repository = ref.watch(dailySummaryRepositoryProvider);
    _dateKey = repository.todayKey;

    ref.onDispose(() async {
      await _mealsSubscription?.cancel();
      await _waterSubscription?.cancel();
    });

    _mealsSubscription = repository.watchTodayMeals().listen((meals) {
      _meals = meals;
      _emit();
    });

    _waterSubscription = repository.watchTodayWater().listen((water) {
      _water = water;
      _emit();
    });

    _meals = await repository.watchTodayMeals().first;
    _water = await repository.watchTodayWater().first;
    return DailySummary(dateKey: _dateKey, meals: _meals, waterGlasses: _water);
  }

  Future<void> addMeal(FoodAnalysisResult result, {String? imagePath}) async {
    await ref.read(dailySummaryRepositoryProvider).addMeal(result, imagePath: imagePath);
  }

  Future<void> setWaterCount(int glasses) async {
    await ref.read(dailySummaryRepositoryProvider).setWaterCount(glasses);
  }

  void _emit() {
    state = AsyncData(
      DailySummary(
        dateKey: _dateKey,
        meals: _meals,
        waterGlasses: _water,
      ),
    );
  }
}

final dailySummaryProvider = AsyncNotifierProvider<DailySummaryNotifier, DailySummary>(
  DailySummaryNotifier.new,
);

final todayExercisesBootstrapProvider = FutureProvider<void>((ref) async {
  final profile = ref.watch(userProfileProvider).asData?.value;
  if (profile == null) {
    return;
  }
  try {
    await ref.read(plannerRepositoryProvider).ensureTodayExercises(profile);
  } catch (_) {}
});

final todayExercisesProvider = StreamProvider<List<WeeklyExerciseItem>>((ref) {
  ref.watch(todayExercisesBootstrapProvider);
  return ref.watch(plannerRepositoryProvider).watchTodayExercises();
});

final activeDoctorNoteProvider = FutureProvider<DoctorNoteRecord?>((ref) async {
  final profile = ref.watch(userProfileProvider).asData?.value;
  final summary = ref.watch(dailySummaryProvider).asData?.value;
  final exercises = ref.watch(todayExercisesProvider).asData?.value;
  if (profile == null || summary == null || exercises == null) {
    return null;
  }

  return ref.read(doctorNoteRepositoryProvider).getOrGenerate(
        profile: profile,
        summary: summary,
        exercises: exercises,
      );
});

final homeDashboardProvider = Provider<HomeDashboardData?>((ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  final summary = ref.watch(dailySummaryProvider).asData?.value;
  final settings = ref.watch(appSettingsProvider).asData?.value ?? const AppSettings();
  final exercises = ref.watch(todayExercisesProvider).asData?.value ?? const <WeeklyExerciseItem>[];
  final doctorNote = ref.watch(activeDoctorNoteProvider).asData?.value;
  if (profile == null || summary == null) {
    return null;
  }

  final targetCalories = (settings.customCalorieGoal ?? profile.dailyCalorieTarget).toDouble();
  final targetMacros = NutritionMacro(
    calories: targetCalories,
    protein: profile.weightKg * 1.5,
    carbs: targetCalories * 0.5 / 4,
    fat: targetCalories * 0.25 / 9,
  );

  return HomeDashboardData(
    doctorNote: doctorNote,
    summary: summary,
    targetMacros: targetMacros,
    consumedMacros: summary.consumedMacros,
    exerciseLogs: exercises,
  );
});
