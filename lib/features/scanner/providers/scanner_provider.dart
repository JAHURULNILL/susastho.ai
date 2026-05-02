import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/food_analysis_result.dart';
import '../../../data/services/ai_backend_service.dart';
import '../../home/providers/home_provider.dart';
import '../../../shared/providers/app_state_provider.dart';

class ScannerState {
  const ScannerState({
    this.image,
    this.result,
    this.isAnalyzing = false,
    this.errorMessage,
    this.description = '',
  });

  final XFile? image;
  final FoodAnalysisResult? result;
  final bool isAnalyzing;
  final String? errorMessage;
  final String description;

  ScannerState copyWith({
    XFile? image,
    FoodAnalysisResult? result,
    bool? isAnalyzing,
    String? errorMessage,
    String? description,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ScannerState(
      image: image ?? this.image,
      result: clearResult ? null : result ?? this.result,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      description: description ?? this.description,
    );
  }
}

class ScannerNotifier extends Notifier<ScannerState> {
  final ImagePicker _picker = ImagePicker();

  @override
  ScannerState build() => const ScannerState();

  void updateDescription(String value) {
    state = state.copyWith(description: value, clearError: true);
  }

  Future<void> pickAndAnalyze(WidgetRef ref) async {
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) {
      state = state.copyWith(errorMessage: 'প্রথমে আপনার প্রোফাইল সম্পূর্ণ করুন।');
      return;
    }

    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
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
      profileDescription: state.description,
    );
  }

  Future<void> analyzeText(WidgetRef ref) async {
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) {
      state = state.copyWith(errorMessage: 'প্রথমে আপনার প্রোফাইল সম্পূর্ণ করুন।');
      return;
    }
    if (state.description.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'কী খেয়েছেন সেটা লিখুন।');
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
      profileDescription: state.description,
    );
  }

  Future<void> _analyze(
    WidgetRef ref, {
    XFile? image,
    String? description,
    String? profileDescription,
  }) async {
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) {
      return;
    }

    try {
      final summary = ref.read(dailySummaryProvider).asData?.value;
      final consumed = summary?.consumedMacros.calories.round();
      final remaining = profile.dailyCalorieTarget - (consumed ?? 0);
      final result = await ref.read(aiBackendServiceProvider).analyzeMeal(
            image: image,
            description: description ?? profileDescription,
            profile: profile,
            consumedCalories: consumed,
            remainingCalories: remaining,
          );
      state = state.copyWith(
        result: result,
        isAnalyzing: false,
      );
    } catch (error) {
      final raw = error.toString();
      final message = raw.contains('BACKEND_BASE_URL')
          ? 'Server URL সেট করা নেই।'
          : raw.contains('GEMINI_API_KEY')
              ? 'Gemini API key backend-এ সেট করা নেই।'
              : raw.contains('MISSING_MEAL_INPUT')
                  ? 'ছবি তুলুন অথবা কী খেয়েছেন লিখুন।'
                  : raw.contains('ECONNREFUSED') || raw.contains('SocketException')
                      ? 'Server পাওয়া যাচ্ছে না।'
                      : 'খাবার বিশ্লেষণ করা যায়নি। আবার চেষ্টা করুন।';

      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: message,
      );
    }
  }

  void clear() {
    state = const ScannerState();
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(
  ScannerNotifier.new,
);
