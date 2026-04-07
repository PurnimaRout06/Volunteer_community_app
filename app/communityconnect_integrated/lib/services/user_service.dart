// lib/services/user_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Profile page API calls.
// ─────────────────────────────────────────────────────────────────────────────

import 'api_config.dart';
import 'http_client.dart';

class UserService {
  static Future<Map<String, dynamic>> getProfile() async {
    final data = await ApiClient.get(ApiConfig.profile);
    return data['user'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getAttendedEvents() async {
    final data = await ApiClient.get(ApiConfig.attendedEvents);
    return data['events'] as List<dynamic>;
  }

  static Future<List<dynamic>> getOrganizedEvents() async {
    final data = await ApiClient.get(ApiConfig.organizedEvents);
    return data['events'] as List<dynamic>;
  }
}
