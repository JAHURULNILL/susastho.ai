import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_strings.dart';
import '../models/wellness_routine.dart';

class WellnessBackendService {
  WellnessBackendService({
    required FirebaseAuth? auth,
    String? baseUrl,
  })  : _auth = auth,
        _baseUrl = (baseUrl ?? const String.fromEnvironment(AppStrings.backendBaseUrlEnv)).trim();

  final FirebaseAuth? _auth;
  final String _baseUrl;

  String get _resolvedBaseUrl {
    if (_baseUrl.isEmpty) {
      throw Exception('BACKEND_BASE_URL is missing');
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
    final response = await http
        .post(
          Uri.parse('$_resolvedBaseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }
}
