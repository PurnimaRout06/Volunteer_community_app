// lib/services/auth_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Handles signup, login, and Google OAuth calls to the backend.
// After a successful auth call, saves the JWT + user data locally.
// ─────────────────────────────────────────────────────────────────────────────

import 'api_config.dart';
import 'http_client.dart';
import 'token_service.dart';

class AuthService {
  // ── Manual signup ──────────────────────────────────────────────────────────
  /// Returns the user map on success, throws ApiException on failure.
  static Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.signup,
      {'username': username, 'email': email, 'password': password},
      requiresAuth: false,
    );
    await TokenService.saveToken(data['token'], data['user']['id']);
    return data['user'] as Map<String, dynamic>;
  }

  // ── Manual login ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.login,
      {'email': email, 'password': password},
      requiresAuth: false,
    );
    await TokenService.saveToken(data['token'], data['user']['id']);
    return data['user'] as Map<String, dynamic>;
  }

  // ── Google OAuth ───────────────────────────────────────────────────────────
  // The mobile app handles the Google Sign-In UI and gets an idToken.
  // Pass that idToken here to verify it with our backend.
  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final data = await ApiClient.post(
      ApiConfig.googleLogin,
      {'idToken': idToken},
      requiresAuth: false,
    );
    await TokenService.saveToken(data['token'], data['user']['id']);
    return data['user'] as Map<String, dynamic>;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    await TokenService.clearToken();
  }
}
