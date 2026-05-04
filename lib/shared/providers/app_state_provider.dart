import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/daily_summary.dart';
import '../../data/models/health_metrics.dart';
import '../../data/models/wellness_snapshot.dart';
import '../../data/repositories/doctor_note_repository.dart';
import '../../data/repositories/daily_summary_repository.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../../data/repositories/health_metrics_repository.dart';
import '../../data/repositories/planner_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/activity_tracking_service.dart';
import '../../data/services/ai_backend_service.dart';
import '../../data/services/firebase_bootstrap_service.dart';
import '../../data/services/health_sync_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/offline_queue_service.dart';
import '../../data/services/offline_sync_service.dart';
import '../../data/services/wellness_insight_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferencesAsync>((ref) {
  return SharedPreferencesAsync();
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return OfflineQueueService(storage);
});

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final queue = ref.watch(offlineQueueServiceProvider);
  final summary = ref.watch(dailySummaryRepositoryProvider);
  final ai = ref.watch(aiBackendServiceProvider);
  return OfflineSyncService(
    queueService: queue,
    dailySummaryRepository: summary,
    aiBackendService: ai,
  );
});

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (Firebase.apps.isEmpty) {
    return null;
  }

  return FirebaseAuth.instance;
});

final authBootstrapProvider = FutureProvider<void>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) {
    return;
  }
  await FirebaseBootstrapService.ensureSignedIn();
});

final firebaseUserProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  ref.watch(authBootstrapProvider);
  if (auth == null) {
    return Stream.value(null);
  }
  return auth.authStateChanges();
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (Firebase.apps.isEmpty) {
    return null;
  }

  return FirebaseFirestore.instance;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  ref.watch(firebaseUserProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return ProfileRepository(
    storage,
    auth: auth,
    firestore: firestore,
  );
});

final dailySummaryRepositoryProvider = Provider<DailySummaryRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  ref.watch(firebaseUserProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return DailySummaryRepository(
    auth: auth,
    firestore: firestore,
    storage: storage,
  );
});

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return AppSettingsRepository(storage);
});

final healthMetricsRepositoryProvider = Provider<HealthMetricsRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  ref.watch(firebaseUserProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return HealthMetricsRepository(
    auth: auth,
    firestore: firestore,
    storage: storage,
  );
});

final activityTrackingServiceProvider = Provider<ActivityTrackingService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final repository = ref.watch(healthMetricsRepositoryProvider);
  final service = ActivityTrackingService(
    storage: storage,
    healthMetricsRepository: repository,
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  final repository = ref.watch(healthMetricsRepositoryProvider);
  return HealthSyncService(repository);
});

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final dailySummaryRepository = ref.watch(dailySummaryRepositoryProvider);
  final healthMetricsRepository = ref.watch(healthMetricsRepositoryProvider);
  ref.watch(firebaseUserProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final aiBackendService = ref.watch(aiBackendServiceProvider);
  return PlannerRepository(
    auth: auth,
    firestore: firestore,
    aiBackendService: aiBackendService,
    storage: storage,
    dailySummaryRepository: dailySummaryRepository,
    healthMetricsRepository: healthMetricsRepository,
  );
});

final doctorNoteRepositoryProvider = Provider<DoctorNoteRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final dailySummaryRepository = ref.watch(dailySummaryRepositoryProvider);
  final healthMetricsRepository = ref.watch(healthMetricsRepositoryProvider);
  ref.watch(firebaseUserProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final aiBackendService = ref.watch(aiBackendServiceProvider);
  return DoctorNoteRepository(
    auth: auth,
    firestore: firestore,
    aiBackendService: aiBackendService,
    storage: storage,
    dailySummaryRepository: dailySummaryRepository,
    healthMetricsRepository: healthMetricsRepository,
  );
});

final notificationPluginProvider = Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final plugin = ref.watch(notificationPluginProvider);
  return NotificationService(plugin);
});

final wellnessInsightServiceProvider = Provider<WellnessInsightService>((ref) {
  return const WellnessInsightService();
});

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    return repository.loadProfile();
  }

  Future<void> save(UserProfile profile) async {
    state = const AsyncLoading();
    final repository = ref.read(profileRepositoryProvider);
    await repository.saveProfile(profile);
    state = AsyncData(profile);
  }

  Future<void> clear() async {
    state = const AsyncLoading();
    final repository = ref.read(profileRepositoryProvider);
    await repository.clearProfile();
    state = const AsyncData(null);
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repository = ref.read(appSettingsRepositoryProvider);
    return repository.load();
  }

  Future<void> save(AppSettings settings) async {
    state = AsyncData(settings);
    await ref.read(appSettingsRepositoryProvider).save(settings);
    if (settings.notificationsEnabled) {
      final profile = ref.read(userProfileProvider).asData?.value;
      final steps = ref.read(todayStepsProvider).asData?.value;
      final sleep = ref.read(todaySleepProvider).asData?.value;
      if (profile != null) {
        final repository = ref.read(dailySummaryRepositoryProvider);
        final meals = await repository.watchTodayMeals().first;
        final water = await repository.watchTodayWater().first;
        await ref.read(notificationServiceProvider).scheduleContextualReminders(
              profile: profile,
              settings: settings,
              summary: DailySummary(
                dateKey: repository.todayKey,
                meals: meals,
                waterGlasses: water,
              ),
              steps: steps,
              sleep: sleep,
            );
      } else {
        await ref.read(notificationServiceProvider).scheduleDailyReminders();
      }
    } else {
      await ref.read(notificationServiceProvider).cancelAll();
    }
  }
}

final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

final todaySleepProvider = StreamProvider<SleepLogRecord?>((ref) {
  return ref.watch(healthMetricsRepositoryProvider).watchTodaySleep();
});

final todayStepsProvider = StreamProvider<StepLogRecord?>((ref) {
  return ref.watch(healthMetricsRepositoryProvider).watchTodaySteps();
});

final weightHistoryProvider = StreamProvider<List<WeightHistoryEntry>>((ref) {
  return ref.watch(healthMetricsRepositoryProvider).watchWeightHistory();
});

final weeklyWaterProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.watch(dailySummaryRepositoryProvider).loadCurrentWeekWater();
});

final weeklyStepsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.watch(healthMetricsRepositoryProvider).loadCurrentWeekSteps();
});

final weeklySleepProvider = FutureProvider<Map<String, double>>((ref) async {
  return ref.watch(healthMetricsRepositoryProvider).loadCurrentWeekSleep();
});

final offlineQueueCountProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(offlineQueueServiceProvider).loadQueue();
  return items.length;
});

final wellnessSnapshotProvider = FutureProvider<WellnessSnapshot?>((ref) async {
  final profile = ref.watch(userProfileProvider).asData?.value;
  if (profile == null) {
    return null;
  }
  final settings = ref.watch(appSettingsProvider).asData?.value ?? const AppSettings();
  final weeklyCalories = await ref.watch(dailySummaryRepositoryProvider).loadCurrentWeekCalories();
  final weeklyWater = await ref.watch(weeklyWaterProvider.future);
  final weeklySteps = await ref.watch(weeklyStepsProvider.future);
  final weeklySleep = await ref.watch(weeklySleepProvider.future);
  final dailyGoal = settings.customCalorieGoal ?? profile.dailyCalorieTarget;

  return ref.watch(wellnessInsightServiceProvider).buildSnapshot(
        profile: profile,
        weeklyCalories: weeklyCalories,
        weeklyWater: weeklyWater,
        weeklySteps: weeklySteps,
        weeklySleep: weeklySleep,
        dailyGoal: dailyGoal,
      );
});
