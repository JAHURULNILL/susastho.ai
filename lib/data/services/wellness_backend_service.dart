import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_strings.dart';
import '../models/wellness_routine.dart';

class WellnessBackendService {
  WellnessBackendService({
    required FirebaseAuth? auth,
    String? baseUrl,
    String? apiKey,
  })  : _auth = auth,
        _baseUrl = (baseUrl ?? const String.fromEnvironment(AppStrings.backendBaseUrlEnv)).trim(),
        _apiKey = (apiKey ?? const String.fromEnvironment(AppStrings.backendApiKeyEnv)).trim();

  final FirebaseAuth? _auth;
  final String _baseUrl;
  final String _apiKey;

  String get _resolvedBaseUrl {
    if (_baseUrl.isEmpty) {
      return 'https://susastho-ai.vercel.app';
    }
    return _baseUrl;
  }

  String get _userId {
    final uid = _auth?.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('AUTH_USER_MISSING');
    }
    return uid;
  }

  Future<void> completeModule({
    required WellnessRoutineType moduleId,
    required int duration,
    Map<String, dynamic> details = const {},
  }) async {
    await _post(
      '/api/wellness/complete',
      {
        'userId': _userId,
        'moduleId': moduleId.key,
        'duration': duration,
        'details': details,
      },
    );
  }

  Future<void> resetNofap() async {
    await _post(
      '/api/wellness/nofap-reset',
      {'userId': _userId},
    );
  }

  Future<String> fetchDailyBenefit() async {
    final data = await _post(
      '/api/wellness/daily-benefit',
      {'userId': _userId},
    );
    return data['benefit'] as String? ?? '';
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

  Future<http.Response> _postWithRetry(Uri uri, {required Map<String, String> headers, required String body, int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final response = await http.post(
          uri,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 30));
        return response;
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          throw Exception('Failed after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }
    throw Exception('Failed to execute request');
  }
}
