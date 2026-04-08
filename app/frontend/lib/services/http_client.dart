// lib/services/http_client.dart
// ─────────────────────────────────────────────────────────────────────────────
// A thin wrapper around Dart's http package.
// Automatically attaches the JWT token to every protected request.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';

class ApiClient {
  /// Build headers — always JSON, plus Bearer token if available
  static Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await TokenService.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── GET ────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String url) async {
    final response = await http.get(Uri.parse(url), headers: await _headers());
    return _parse(response);
  }

  // ── POST ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(requiresAuth: requiresAuth),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  // ── PUT ────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(String url, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String url) async {
    final response = await http.delete(Uri.parse(url), headers: await _headers());
    return _parse(response);
  }

  // ── PATCH ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> patch(String url, [Map<String, dynamic>? body]) async {
    final response = await http.patch(
      Uri.parse(url),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _parse(response);
  }

  /// Decode response and surface errors clearly
  static Map<String, dynamic> _parse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    // Throw with the error message from the backend
    throw ApiException(decoded['error'] ?? 'An error occurred', response.statusCode);
  }
}

/// Custom exception carrying the backend error message and HTTP status code
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
