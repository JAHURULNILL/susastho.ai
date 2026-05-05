import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wellness_routine.dart';
import '../../../data/repositories/wellness_routine_repository.dart';
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
  StreamSubscription<Map<WellnessRoutineType, WellnessStreakRecord>>? _streakSubscription;
  StreamSubscription<Set<String>>? _todayLogsSubscription;
  StreamSubscription<Map<String, Set<String>>>? _weekLogsSubscription;
  StreamSubscription<NofapTrackerRecord?>? _nofapSubscription;

  Map<WellnessRoutineType, WellnessStreakRecord> _streaks = const {};
  Set<String> _todayLogs = const <String>{};
  Map<String, Set<String>> _weekLogs = const {};
  NofapTrackerRecord? _nofapTracker;
  String _dailyBenefit = '';
  bool _isLoadingBenefit = true;
  String _dateKey = '';

  @override
  Future<WellnessRoutinePlan?> build() async {
    final profile = ref.watch(userProfileProvider).asData?.value;
    final user = ref.watch(firebaseUserProvider).asData?.value;
    if (profile == null || user == null) {
      return null;
    }

    final repository = ref.watch(wellnessRoutineRepositoryProvider);
    _dateKey = repository.todayKey;
    _dailyBenefit = await repository.readCachedDailyBenefit() ?? '';
    _bindStreams(repository);
    unawaited(refreshDailyBenefit());
    ref.onDispose(_disposeSubscriptions);
    return _composeState();
  }

  Future<void> completeModule(
    WellnessRoutineType type, {
    required int duration,
    Map<String, dynamic> details = const {},
  }) async {
    if (state.value == null) {
      return;
    }
    await ref.read(wellnessRoutineRepositoryProvider).completeModule(
          moduleId: type,
          duration: duration,
          details: details,
        );
    await ref.read(doctorNoteRepositoryProvider).expireAll();
    await refreshDailyBenefit();
  }

  Future<void> resetNofap() async {
    if (state.value == null) {
      return;
    }
    await ref.read(wellnessRoutineRepositoryProvider).resetNofap();
    await ref.read(doctorNoteRepositoryProvider).expireAll();
    await refreshDailyBenefit();
  }

  Future<void> refreshDailyBenefit() async {
    if (state.value == null) {
      return;
    }
    _isLoadingBenefit = true;
    _emit();
    try {
      final benefit = await ref.read(wellnessRoutineRepositoryProvider).fetchDailyBenefit();
      _dailyBenefit = benefit;
    } catch (_) {
      if (_dailyBenefit.isEmpty) {
        _dailyBenefit = 'আজকের wellness অভ্যাসগুলো ধীরে ধীরে সম্পন্ন করুন।';
      }
    } finally {
      _isLoadingBenefit = false;
      _emit();
    }
  }

  void _bindStreams(WellnessRoutineRepository repository) {
    _disposeSubscriptions();
    _streakSubscription = repository.watchStreaks().listen((value) {
      _streaks = value;
      _emit();
    });
    _todayLogsSubscription = repository.watchTodayLogs().listen((value) {
      _todayLogs = value;
      _emit();
    });
    _weekLogsSubscription = repository.watchCurrentWeekLogs().listen((value) {
      _weekLogs = value;
      _emit();
    });
    _nofapSubscription = repository.watchNofapTracker().listen((value) {
      _nofapTracker = value;
      _emit();
    });
  }

  void _disposeSubscriptions() {
    _streakSubscription?.cancel();
    _todayLogsSubscription?.cancel();
    _weekLogsSubscription?.cancel();
    _nofapSubscription?.cancel();
    _streakSubscription = null;
    _todayLogsSubscription = null;
    _weekLogsSubscription = null;
    _nofapSubscription = null;
  }

  WellnessRoutinePlan _composeState() {
    return WellnessRoutinePlan(
      dateKey: _dateKey,
      streaks: Map<WellnessRoutineType, WellnessStreakRecord>.from(_streaks),
      todayLogs: Set<String>.from(_todayLogs),
      weekLogs: {
        for (final entry in _weekLogs.entries) entry.key: Set<String>.from(entry.value),
      },
      nofapTracker: _nofapTracker,
      dailyBenefit: _dailyBenefit,
      isLoadingBenefit: _isLoadingBenefit,
    );
  }

  void _emit() {
    if (_dateKey.isEmpty) {
      return;
    }
    state = AsyncData(_composeState());
  }
}

final wellnessRoutineProvider =
    AsyncNotifierProvider<WellnessRoutineNotifier, WellnessRoutinePlan?>(
  WellnessRoutineNotifier.new,
);
