// lib/services/notification_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Notification tab API calls.
// ─────────────────────────────────────────────────────────────────────────────

import 'api_config.dart';
import 'http_client.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getNotifications() async {
    final data = await ApiClient.get(ApiConfig.notifications);
    return data; // { notifications: [...], unreadCount: N }
  }

  static Future<void> markAsRead(String id) async {
    await ApiClient.patch(ApiConfig.markRead(id));
  }

  static Future<void> markAllAsRead() async {
    await ApiClient.patch(ApiConfig.markAllRead);
  }
}
