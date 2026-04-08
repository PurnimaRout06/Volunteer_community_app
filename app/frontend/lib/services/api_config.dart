// lib/services/api_config.dart
// ─────────────────────────────────────────────────────────────────────────────
// Central config for all API calls.
// Change baseUrl to your server's address when deploying.
// ─────────────────────────────────────────────────────────────────────────────

class ApiConfig {
  // ── Local development ──────────────────────────────────────────────────────
  // Android emulator uses 10.0.2.2 to reach the host machine's localhost.
  // iOS simulator and physical devices use your machine's local IP (e.g. 192.168.1.x).
  // Change this to your deployed server URL for production.
  
  // For Local Development — Choose one:
  // Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // iOS Simulator, Windows Desktop, or Web:
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Physical Device (use your machine's IP from 'ipconfig'):
  //static const String baseUrl = 'http://10.245.197.117:3000/api';

  // ── Endpoints ──────────────────────────────────────────────────────────────
  // Auth
  static const String signup      = '$baseUrl/auth/signup';
  static const String login       = '$baseUrl/auth/login';
  static const String googleLogin = '$baseUrl/auth/google';

  // Events
  static const String events         = '$baseUrl/events';
  static const String upcomingEvents = '$baseUrl/events/upcoming';
  static const String searchEvents   = '$baseUrl/events/search';
  static const String featuredEvent  = '$baseUrl/events/featured';

  // Users
  static const String profile         = '$baseUrl/users/profile';
  static const String attendedEvents  = '$baseUrl/users/attended-events';
  static const String organizedEvents = '$baseUrl/users/organized-events';
  static String registerEvent(String eventId) => '$baseUrl/users/register-event/$eventId';

  // Notifications
  static const String notifications = '$baseUrl/notifications';
  static const String markAllRead   = '$baseUrl/notifications/read-all';
  static String markRead(String id) => '$baseUrl/notifications/$id/read';

  // Chats
  static const String chats = '$baseUrl/chats';
  static String chatMessages(String chatId) => '$baseUrl/chats/$chatId/messages';
}
