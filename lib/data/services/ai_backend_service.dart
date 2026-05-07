import 'dart:convert';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_strings.dart';
import '../models/food_analysis_result.dart';
import '../models/user_profile.dart';
import '../models/weekly_plan.dart';

final aiBackendServiceProvider = Provider<AiBackendService>((ref) {
  return AiBackendService();
});

class AiBackendService {
  AiBackendService({String? baseUrl, String? apiKey})
      : _baseUrl = (baseUrl ?? const String.fromEnvironment(AppStrings.backendBaseUrlEnv)).trim(),
        _apiKey = (apiKey ?? const String.fromEnvironment(AppStrings.backendApiKeyEnv)).trim();

  final String _baseUrl;
  final String _apiKey;

  String get _resolvedBaseUrl {
    if (_baseUrl.isEmpty) {
      return 'https://susastho-ai.vercel.app';
    }
    return _baseUrl;
  }

  Future<FoodAnalysisResult> analyzeMeal({
    XFile? image,
    String? description,
    required UserProfile profile,
    int? consumedCalories,
    int? remainingCalories,
    String mode = 'meal',
    List<Map<String, dynamic>> recentMeals = const [],
    Map<String, dynamic>? healthContext,
  }) async {
    if (image == null && (description == null || description.trim().isEmpty)) {
      throw Exception('MISSING_MEAL_INPUT');
    }

    final payload = <String, dynamic>{
      'profile': profile.toJson(),
      'consumedCalories': consumedCalories,
      'remainingCalories': remainingCalories,
      'mode': mode,
      'recentMeals': recentMeals,
      'healthContext': healthContext,
    };

    if (image != null) {
      final bytes = await image.readAsBytes();
      payload['imageBase64'] = base64Encode(bytes);
      payload['mimeType'] = _detectMimeType(image.path);
    }

    if (description != null && description.trim().isNotEmpty) {
      payload['description'] = description.trim();
    }

    final uri = Uri.parse('$_resolvedBaseUrl/api/nutrition/analyze');
    final response = await _postWithRetry(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'x-api-key': _apiKey,
      },
      body: jsonEncode(payload),
      maxRetries: 1,
      timeout: const Duration(seconds: 8),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['analysis'] == null) {
      throw Exception('Analysis content is missing in backend response: ${response.body}');
    }
    final analysis = Map<String, dynamic>.from(decoded['analysis'] as Map);
    final model = decoded['model'];
    if (model is Map<String, dynamic>) {
      analysis['model'] = model;
    }
    return FoodAnalysisResult.fromJson(analysis);
  }

  Future<GeneratedDoctorNote> generateDoctorNote({
    required UserProfile profile,
    required dynamic summary,
    required List<WeeklyExerciseItem> exercises,
    required List<String> recentCategories,
    Map<String, dynamic>? historicalContext,
  }) async {
    final completedExercises = exercises.where((item) => item.completed).toList();
    final payload = <String, dynamic>{
      'profile': profile.toJson(),
      'recentCategories': recentCategories,
      'todayData': {
        'totalCal': summary.consumedMacros.calories.round(),
        'totalProtein': summary.consumedMacros.protein,
        'totalCarbs': summary.consumedMacros.carbs,
        'totalFat': summary.consumedMacros.fat,
        'waterLog': summary.waterGlasses,
        'exerciseDone': completedExercises.length,
        'burnedCal': completedExercises.fold<double>(0, (sum, item) => sum + item.caloriesBurned),
        'remainCal': profile.dailyCalorieTarget - summary.consumedMacros.calories.round(),
      },
      'historicalContext': historicalContext,
    };

    final decoded = await _post('/api/doctor-note', payload);
    return GeneratedDoctorNote(
      content: decoded['content'] as String? ?? '',
      category: decoded['category'] as String? ?? 'condition_specific',
      contextSnapshot: Map<String, dynamic>.from(decoded['contextSnapshot'] as Map? ?? const {}),
    );
  }

  Future<List<WeeklyExerciseItem>> generateExercisePlan({
    required UserProfile profile,
    Map<String, dynamic>? historicalContext,
  }) async {
    final decoded = await _post('/api/exercise-plan', {
      'profile': profile.toJson(),
      'historicalContext': historicalContext,
    });
    final items = (decoded['items'] as List<dynamic>? ?? const []);
    return items
        .map((item) => WeeklyExerciseItem.fromJson('', Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<WeeklyMealPlan> generateMealPlan({
    required UserProfile profile,
    required String weekOf,
    Map<String, dynamic>? historicalContext,
  }) async {
    final decoded = await _post(
      '/api/meal-plan',
      {
        'profile': profile.toJson(),
        'weekOf': weekOf,
        'historicalContext': historicalContext,
      },
    );
    return WeeklyMealPlan.fromJson(Map<String, dynamic>.from(decoded['plan'] as Map? ?? const {}));
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_resolvedBaseUrl$path');
    final response = await _postWithRetry(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'x-api-key': _apiKey,
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<http.Response> _postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final response = await http.post(
          uri,
          headers: headers,
          body: body,
        ).timeout(timeout);
        return response;
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw Exception('Failed after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 1 * attempts)); // Exponential backoff
      }
    }
    throw Exception('Failed to execute request');
  }

  String _detectMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}

class GeneratedDoctorNote {
  const GeneratedDoctorNote({
    required this.content,
    required this.category,
    required this.contextSnapshot,
  });

  final String content;
  final String category;
  final Map<String, dynamic> contextSnapshot;
}
