import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/services/activity_storage_service.dart';
import '../models/gps_point.dart';
import '../models/conquest_result_model.dart';
import '../models/territory_model.dart';

class ActivitySubmissionResult {
  final bool success;
  final bool queuedOffline;
  final String? activityId;
  final double? distanceKm;
  final int? xpEarned;
  final int? coinsEarned;
  final String? message;
  final bool territoryAwarded;
  final ConquestResultModel? conquestResult;

  const ActivitySubmissionResult({
    required this.success,
    this.queuedOffline = false,
    this.activityId,
    this.distanceKm,
    this.xpEarned,
    this.coinsEarned,
    this.message,
    this.territoryAwarded = false,
    this.conquestResult,
  });
}

class BackendActivityService {
  final http.Client _client;
  final String? customBaseUrl;

  BackendActivityService({http.Client? client, this.customBaseUrl})
      : _client = client ?? http.Client();

  String get baseUrl {
    if (customBaseUrl != null) return customBaseUrl!;
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  /// Submits completed activity telemetry to the backend engine.
  /// If the network fails, automatically persists to local offline queue.
  Future<ActivitySubmissionResult> submitActivity({
    required String userId,
    required List<GpsPoint> points,
    required int steps,
    required int durationSeconds,
    required String activityType,
  }) async {
    final payload = {
      'userId': userId,
      'points': points.map((p) => p.toJson()).toList(),
      'steps': steps,
      'durationSeconds': durationSeconds,
      'activityType': activityType,
    };

    try {
      final url = Uri.parse('$baseUrl/api/activities/submit');
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final activity = body['activity'] as Map<String, dynamic>?;
        final rewards = body['rewards'] as Map<String, dynamic>?;
        final territoryAwarded = body['territoryAwarded'] == true;

        final conquestResult = ConquestResultModel.fromJson(
          body,
          points: points
              .map((p) => MapCoordinate(lat: p.latitude, lng: p.longitude))
              .toList(),
        );

        return ActivitySubmissionResult(
          success: true,
          activityId: activity?['id'] as String?,
          distanceKm: (activity?['distanceKm'] as num?)?.toDouble(),
          xpEarned: (rewards?['xp'] as num?)?.toInt(),
          coinsEarned: (rewards?['coins'] as num?)?.toInt(),
          message: conquestResult.message,
          territoryAwarded: territoryAwarded,
          conquestResult: conquestResult,
        );
      } else {
        // Non-200 response: queue offline
        await ActivityStorageService.enqueueOfflineActivity(payload);
        return ActivitySubmissionResult(
          success: false,
          queuedOffline: true,
          message:
              'Backend responded with status ${response.statusCode}. Queued offline.',
        );
      }
    } catch (e) {
      // Network failure, timeout, or unreachable backend: enqueue offline
      await ActivityStorageService.enqueueOfflineActivity(payload);
      return ActivitySubmissionResult(
        success: false,
        queuedOffline: true,
        message: 'Network offline. Activity safely queued locally: $e',
      );
    }
  }

  /// Drains and submits any locally queued offline activities.
  Future<int> syncPendingActivities() async {
    final queue = await ActivityStorageService.getOfflineQueue();
    if (queue.isEmpty) return 0;

    int syncedCount = 0;
    final List<Map<String, dynamic>> remainingQueue = [];

    for (final item in queue) {
      final data = item['data'] as Map<String, dynamic>?;
      if (data == null) continue;

      try {
        final url = Uri.parse('$baseUrl/api/activities/submit');
        final response = await _client
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 6));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          syncedCount++;
        } else {
          remainingQueue.add(item);
        }
      } catch (_) {
        remainingQueue.add(item);
      }
    }

    if (remainingQueue.isEmpty) {
      await ActivityStorageService.clearOfflineQueue();
    }
    return syncedCount;
  }
}
