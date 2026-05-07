import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/food_analysis_result.dart';
import '../../../data/models/daily_summary.dart';
import '../../../data/models/offline_queue_item.dart';
import '../../../data/services/ai_backend_service.dart';
import '../../home/providers/home_provider.dart';
import '../../../shared/providers/app_state_provider.dart';

enum ScanInputMode {
  meal,
  menu,
  receipt,
}

class ScannerState {
  const ScannerState({
    this.image,
    this.result,
    this.isAnalyzing = false,
    this.errorMessage,
    this.description = '',
    this.mode = ScanInputMode.meal,
    this.mealSlot = MealSlot.morning,
  });

  final XFile? image;
  final FoodAnalysisResult? result;
  final bool isAnalyzing;
  final String? errorMessage;
  final String description;
  final ScanInputMode mode;
  final MealSlot mealSlot;

  ScannerState copyWith({
    XFile? image,
    FoodAnalysisResult? result,
    bool? isAnalyzing,
    String? errorMessage,
    String? description,
    ScanInputMode? mode,
    MealSlot? mealSlot,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ScannerState(
      image: image ?? this.image,
      result: clearResult ? null : result ?? this.result,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      description: description ?? this.description,
      mode: mode ?? this.mode,
      mealSlot: mealSlot ?? this.mealSlot,
    );
  }
}

class ScannerNotifier extends Notifier<ScannerState> {
  final ImagePicker _picker = ImagePicker();

  @override
  ScannerState build() => ScannerState(
        mealSlot: MealSlotX.fromHour(DateTime.now().hour),
      );

  void updateDescription(String value) {
    state = state.copyWith(description: value, clearError: true);
  }

  void setMode(ScanInputMode mode) {
    state = state.copyWith(mode: mode, clearError: true, clearResult: true);
  }

  void setMealSlot(MealSlot slot) {
    state = state.copyWith(mealSlot: slot, clearError: true);
  }

  Future<void> pickAndAnalyze(WidgetRef ref) async {
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) {
      state = state.copyWith(errorMessage: 'প্রথমে আপনার প্রোফাইল সম্পূর্ণ করুন।');
      return;
    }

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (file == null) {
      return;
    }

    state = state.copyWith(
      image: file,
      isAnalyzing: true,
      clearError: true,
      clearResult: true,
    );

    await _analyze(
      ref,
      image: file,
      effectiveDescription: state.description,
    );
  }

  Future<void> analyzeText(WidgetRef ref) async {
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) {
      state = state.copyWith(errorMessage: 'প্রথমে আপনার প্রোফাইল সম্পূর্ণ করুন।');
      return;
    }
    if (state.description.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'কি খেয়েছেন বা কি দেখতে চাইছেন সেটা লিখুন।');
      return;
    }

    state = state.copyWith(
      isAnalyzing: true,
      clearError: true,
      clearResult: true,
    );

    await _analyze(
      ref,
      description: state.description,
      effectiveDescription: state.description,
    );
  }

  Future<void> _analyze(
    WidgetRef ref, {
    XFile? image,
    String? description,
    String? effectiveDescription,
  }) async {
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) {
      return;
    }

    try {
      final summary = ref.read(dailySummaryProvider).asData?.value;
      final consumed = summary?.consumedMacros.calories.round();
      final remaining = profile.dailyCalorieTarget - (consumed ?? 0);
      final history = await ref.read(dailySummaryRepositoryProvider).loadHistoricalContext();
      final recentMeals = List<Map<String, dynamic>>.from(
        history['recentMeals'] as List? ?? const [],
      );

      final result = await ref.read(aiBackendServiceProvider).analyzeMeal(
            image: image,
            description: description ?? effectiveDescription,
            profile: profile,
            consumedCalories: consumed,
            remainingCalories: remaining,
            mode: state.mode.name,
            recentMeals: recentMeals,
            healthContext: history,
          );
      state = state.copyWith(
        result: result,
        isAnalyzing: false,
      );
    } catch (error, stackTrace) {
      print('DEBUG: Scanner Exception caught in scanner_provider.dart: $error');
      print(stackTrace);
      final raw = error.toString();
      if (_isNetworkError(raw)) {
        await ref.read(offlineQueueServiceProvider).enqueue(
              OfflineQueueItem(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                type: switch (state.mode) {
                  ScanInputMode.meal => OfflineQueueItemType.mealScan,
                  ScanInputMode.menu => OfflineQueueItemType.menuScan,
                  ScanInputMode.receipt => OfflineQueueItemType.receiptScan,
                },
                createdAt: DateTime.now(),
                payload: {
                  'imagePath': image?.path,
                  'description': description ?? effectiveDescription,
                  'profile': profile.toJson(),
                  'mode': state.mode.name,
                  'mealSlot': state.mealSlot.key,
                },
              ),
            );
        ref.invalidate(offlineQueueCountProvider);
      }

      final message = raw.contains('BACKEND_BASE_URL')
          ? 'Server URL সেট করা নেই।'
          : raw.contains('GEMINI_API_KEY')
              ? 'Gemini API key backend-এ সেট করা নেই।'
              : raw.contains('MISSING_MEAL_INPUT')
                  ? 'ছবি তুলুন অথবা বর্ণনা লিখুন।'
                  : _isNetworkError(raw)
                      ? 'নেটওয়ার্ক পাওয়া যাচ্ছে না। আপনার ইনপুট সেভ রাখা হয়েছে, পরে sync হবে।'
                      : 'বিশ্লেষণ করা যায়নি। (${raw.replaceFirst('Exception: ', '')})';

      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: message,
      );
    }
  }

  bool _isNetworkError(String raw) {
    return raw.contains('SocketException') ||
        raw.contains('ECONNREFUSED') ||
        raw.contains('TimeoutException') ||
        raw.contains('timed out') ||
        raw.contains('failed host lookup');
  }

  void clear() {
    state = ScannerState(
      mealSlot: MealSlotX.fromHour(DateTime.now().hour),
    );
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(
  ScannerNotifier.new,
);
