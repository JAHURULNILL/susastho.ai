import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_strings.dart';
import '../models/food_analysis_result.dart';
import '../models/user_profile.dart';

final aiBackendServiceProvider = Provider<AiBackendService>((ref) {
  return AiBackendService();
});

class AiBackendService {
  AiBackendService({
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            (Firebase.apps.isEmpty
                ? null
                : FirebaseFunctions.instanceFor(
                    region: const String.fromEnvironment(
                      AppStrings.firebaseFunctionsRegionEnv,
                      defaultValue: 'asia-south1',
                    ),
                  ));

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _resolvedFunctions {
    final functions = _functions;
    if (functions == null) {
      throw Exception('FIREBASE_NOT_INITIALIZED');
    }
    return functions;
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

    final callable = _resolvedFunctions.httpsCallable('analyzeFood');
    final response = await callable.call<Map<String, dynamic>>(payload);
    final decoded = Map<String, dynamic>.from(response.data);
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
