// lib/services/chat_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Chat tab API calls.
// ─────────────────────────────────────────────────────────────────────────────

import 'api_config.dart';
import 'http_client.dart';

class ChatService {
  static Future<List<dynamic>> getChatList() async {
    final data = await ApiClient.get(ApiConfig.chats);
    return data['chats'] as List<dynamic>;
  }

  static Future<List<dynamic>> getMessages(String chatId) async {
    final data = await ApiClient.get(ApiConfig.chatMessages(chatId));
    return data['messages'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> sendMessage(String chatId, String content) async {
    final data = await ApiClient.post(ApiConfig.chatMessages(chatId), {'content': content});
    return data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> startChat(String organizerId, {String? eventId}) async {
    final data = await ApiClient.post(ApiConfig.chats, {
      'organizerId': organizerId,
      if (eventId != null) 'eventId': eventId,
    });
    return data['chat'] as Map<String, dynamic>;
  }
}
