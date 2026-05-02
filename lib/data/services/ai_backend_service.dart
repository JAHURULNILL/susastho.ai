import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_strings.dart';
import '../models/food_analysis_result.dart';
import '../models/user_profile.dart';

final aiBackendServiceProvider = Provider<AiBackendService>((ref) {
  return AiBackendService();
});

class AiBackendService {
  AiBackendService({String? baseUrl})
      : _baseUrl = (baseUrl ?? const String.fromEnvironment(AppStrings.backendBaseUrlEnv)).trim();

  final String _baseUrl;

  String get _resolvedBaseUrl {
    if (_baseUrl.isEmpty) {
      throw Exception('BACKEND_BASE_URL is missing');
    }
    return _baseUrl;
  }

  Future<FoodAnalysisResult> analyzeFood({
    required XFile image,
    required UserProfile profile,
  }) async {
    final bytes = await image.readAsBytes();
    final payload = {
      'imageBase64': base64Encode(bytes),
      'mimeType': _detectMimeType(image.path),
      'profile': profile.toJson(),
    };

    final uri = Uri.parse('$_resolvedBaseUrl/api/nutrition/analyze');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final analysis = Map<String, dynamic>.from(decoded['analysis'] as Map<String, dynamic>);
    final model = decoded['model'];
    if (model is Map<String, dynamic>) {
      analysis['model'] = model;
    }
    return FoodAnalysisResult.fromJson(analysis);
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
