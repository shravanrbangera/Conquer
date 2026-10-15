import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/territory_model.dart';
import '../models/territory_event_model.dart';
import '../models/notification_model.dart';
import '../models/achievement_model.dart';
import '../models/user_model.dart';

class BackendTerritoryService {
  final http.Client _client;
  final String? customBaseUrl;

  BackendTerritoryService({http.Client? client, this.customBaseUrl})
      : _client = client ?? http.Client();

  String get baseUrl {
    if (customBaseUrl != null) return customBaseUrl!;
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  /// Fetches all active nearby territories from backend
  Future<List<TerritoryModel>> fetchNearbyTerritories() async {
    final url = Uri.parse('$baseUrl/api/territories/nearby');
    final response = await _client.get(url).timeout(const Duration(seconds: 5));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['territories'] as List<dynamic>? ?? [];
      return list
          .map((t) => TerritoryModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load territories: HTTP ${response.statusCode}');
  }

  /// Fetches recent territory conquest and capture event history
  Future<List<TerritoryEventModel>> fetchTerritoryEvents() async {
    final url = Uri.parse('$baseUrl/api/territories/events');
    final response = await _client.get(url).timeout(const Duration(seconds: 5));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['events'] as List<dynamic>? ?? [];
      return list
          .map((e) => TerritoryEventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load territory events: HTTP ${response.statusCode}');
  }

  /// Fetches notifications for a specific user
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    final url = Uri.parse('$baseUrl/api/notifications?userId=$userId');
    final response = await _client.get(url).timeout(const Duration(seconds: 5));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['notifications'] as List<dynamic>? ?? [];
      return list
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load notifications: HTTP ${response.statusCode}');
  }

  /// Marks a notification as read
  Future<bool> markNotificationAsRead(String id, String userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/notifications/$id/read?userId=$userId');
      final response = await _client.post(url).timeout(const Duration(seconds: 4));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Fetches achievements for a specific user
  Future<List<AchievementModel>> fetchAchievements(String userId) async {
    final url = Uri.parse('$baseUrl/api/achievements?userId=$userId');
    final response = await _client.get(url).timeout(const Duration(seconds: 5));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['achievements'] as List<dynamic>? ?? [];
      return list
          .map((a) => AchievementModel.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load achievements: HTTP ${response.statusCode}');
  }

  /// Fetches current user profile from backend
  Future<UserModel> fetchUserProfile(String userId) async {
    final url = Uri.parse('$baseUrl/api/auth/me?userId=$userId');
    final response = await _client.get(url).timeout(const Duration(seconds: 5));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load user profile: HTTP ${response.statusCode}');
  }

  /// Switches active account on backend (e.g. between u_shravan and u_rahul)
  Future<UserModel> switchUser(String userId) async {
    final url = Uri.parse('$baseUrl/api/auth/switch');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    }
    throw Exception('Failed to switch user: HTTP ${response.statusCode}');
  }
}
