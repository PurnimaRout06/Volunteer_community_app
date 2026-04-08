// lib/services/event_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// All event-related API calls (Search tab + Home tab).
// ─────────────────────────────────────────────────────────────────────────────

import 'api_config.dart';
import 'http_client.dart';

class EventService {
  // ── Upcoming events (Search tab default list) ──────────────────────────────
  static Future<List<dynamic>> getUpcomingEvents() async {
    final data = await ApiClient.get(ApiConfig.upcomingEvents);
    return data['events'] as List<dynamic>;
  }

  // ── Search + filter (Search tab) ──────────────────────────────────────────
  // Pass any combination of: q, location, category, date (YYYY-MM-DD)
  static Future<List<dynamic>> searchEvents({
    String? q,
    String? location,
    String? category,
    String? date,
  }) async {
    final params = <String, String>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (location != null && location.isNotEmpty) params['location'] = location;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (date != null && date.isNotEmpty) params['date'] = date;

    final uri = Uri.parse(ApiConfig.searchEvents).replace(queryParameters: params);
    final data = await ApiClient.get(uri.toString());
    return data['events'] as List<dynamic>;
  }

  // ── Featured event (Home tab) ──────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getFeaturedEvent() async {
    try {
      final data = await ApiClient.get(ApiConfig.featuredEvent);
      return data['event'] as Map<String, dynamic>;
    } catch (_) {
      return null; // No featured event set
    }
  }

  // ── Get single event ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEvent(String id) async {
    final data = await ApiClient.get('${ApiConfig.events}/$id');
    return data['event'] as Map<String, dynamic>;
  }

  // ── Create event ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createEvent({
    required String title,
    required String date,
    String? description,
    String? category,
    String? location,
    String? time,
    String? imageUrl,
    bool isFeatured = false,
  }) async {
    final data = await ApiClient.post(ApiConfig.events, {
      'title': title,
      'date': date,
      'description': description,
      'category': category,
      'location': location,
      'time': time,
      'imageUrl': imageUrl,
      'isFeatured': isFeatured,
    });
    return data['event'] as Map<String, dynamic>;
  }

  // ── Edit event ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> editEvent(String id, Map<String, dynamic> updates) async {
    final data = await ApiClient.put('${ApiConfig.events}/$id', updates);
    return data['event'] as Map<String, dynamic>;
  }

  // ── Delete event ───────────────────────────────────────────────────────────
  static Future<void> deleteEvent(String id) async {
    await ApiClient.delete('${ApiConfig.events}/$id');
  }

  // ── Register for event ─────────────────────────────────────────────────────
  static Future<void> registerForEvent(String eventId) async {
    await ApiClient.post(ApiConfig.registerEvent(eventId), {});
  }
}
