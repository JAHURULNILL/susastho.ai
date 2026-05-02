import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/food_analysis_result.dart';
import '../../../data/services/ai_backend_service.dart';
import '../../../shared/providers/app_state_provider.dart';

class ScannerState {
  const ScannerState({
    this.image,
    this.result,
    this.isAnalyzing = false,
    this.errorMessage,
  });

  final XFile? image;
  final FoodAnalysisResult? result;
  final bool isAnalyzing;
  final String? errorMessage;

  ScannerState copyWith({
    XFile? image,
    FoodAnalysisResult? result,
    bool? isAnalyzing,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ScannerState(
      image: image ?? this.image,
      result: clearResult ? null : result ?? this.result,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ScannerNotifier extends Notifier<ScannerState> {
  final ImagePicker _picker = ImagePicker();

  @override
  ScannerState build() => const ScannerState();

  Future<void> pickAndAnalyze(WidgetRef ref) async {
    final profile = ref.read(userProfileProvider).asData?.value;
    if (profile == null) {
      state = state.copyWith(
        errorMessage: 'প্রথমে আপনার প্রোফাইল সম্পূর্ণ করুন।',
      );
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

    try {
      final result = await ref.read(aiBackendServiceProvider).analyzeFood(
            image: file,
            profile: profile,
          );
      state = state.copyWith(
        result: result,
        isAnalyzing: false,
      );
    } catch (error) {
      final raw = error.toString();
      final message = raw.contains('FIREBASE_NOT_INITIALIZED')
          ? 'Firebase setup complete হয়নি।'
          : raw.contains('unauthenticated')
              ? 'User session পাওয়া যায়নি। আবার app খুলুন।'
              : raw.contains('permission-denied')
                  ? 'এই request এখন অনুমোদিত নয়।'
                  : raw.contains('internal')
                      ? 'Gemini analysis এখন পাওয়া যায়নি। একটু পরে আবার চেষ্টা করুন।'
                      : raw.contains('network-request-failed') || raw.contains('SocketException')
                          ? 'ইন্টারনেট বা cloud connection পাওয়া যাচ্ছে না।'
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
