import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../models/daily_summary.dart';
import '../models/food_analysis_result.dart';
import '../models/offline_queue_item.dart';
import '../models/user_profile.dart';
import '../repositories/daily_summary_repository.dart';
import 'ai_backend_service.dart';
import 'offline_queue_service.dart';

class OfflineSyncService {
  OfflineSyncService({
    required OfflineQueueService queueService,
    required DailySummaryRepository dailySummaryRepository,
    required AiBackendService aiBackendService,
  })  : _queueService = queueService,
        _dailySummaryRepository = dailySummaryRepository,
        _aiBackendService = aiBackendService;

  final OfflineQueueService _queueService;
  final DailySummaryRepository _dailySummaryRepository;
  final AiBackendService _aiBackendService;

  Future<int> processQueue() async {
    final items = await _queueService.loadQueue();
    var processed = 0;
    for (final item in items) {
      try {
        final result = await _runItem(item);
        if (result != null && item.type == OfflineQueueItemType.mealScan) {
          final slotKey = item.payload['mealSlot'] as String?;
          await _dailySummaryRepository.addMeal(
            result,
            imagePath: item.payload['imagePath'] as String?,
            slot: slotKey == null ? null : MealSlotX.fromKey(slotKey),
          );
        }
        await _queueService.remove(item.id);
        processed += 1;
      } catch (_) {
        // Keep item for the next sync attempt.
      }
    }
    return processed;
  }

  Future<FoodAnalysisResult?> _runItem(OfflineQueueItem item) async {
    final profile = UserProfile.fromJson(Map<String, dynamic>.from(item.payload['profile'] as Map? ?? const {}));
    final description = item.payload['description'] as String?;
    final imagePath = item.payload['imagePath'] as String?;
    final recent = await _dailySummaryRepository.loadHistoricalContext();
    final recentMeals = List<Map<String, dynamic>>.from(recent['recentMeals'] as List? ?? const []);

    XFile? image;
    if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
      image = XFile(imagePath);
    }

    return _aiBackendService.analyzeMeal(
      image: image,
      description: description,
      profile: profile,
      mode: item.payload['mode'] as String? ?? 'meal',
      recentMeals: recentMeals,
      healthContext: recent,
    );
  }
}
