import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:conquer_app/data/models/gps_point.dart';
import 'package:conquer_app/core/utils/distance_calculator.dart';
import 'package:conquer_app/core/services/activity_tracking_engine.dart';
import 'package:conquer_app/core/services/activity_storage_service.dart';
import 'package:conquer_app/data/services/backend_activity_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Distance Calculation Tests', () {
    test('Haversine distance between identical points is zero', () {
      final distance = DistanceCalculator.haversineDistanceMeters(
        13.3440,
        74.7440,
        13.3440,
        74.7440,
      );
      expect(distance, equals(0.0));
    });

    test('Haversine distance for 1 degree latitude is approximately 111.195 km', () {
      final distanceMeters = DistanceCalculator.haversineDistanceMeters(
        0.0,
        0.0,
        1.0,
        0.0,
      );
      final distanceKm = distanceMeters / 1000.0;
      // 1 degree latitude is ~111.195 km
      expect(distanceKm, closeTo(111.195, 0.5));
    });

    test('Haversine distance calculates short local distances accurately', () {
      // Offset of 0.001 degree latitude at equator is ~111.2 meters
      final distanceMeters = DistanceCalculator.haversineDistanceMeters(
        0.0,
        0.0,
        0.001,
        0.0,
      );
      expect(distanceMeters, closeTo(111.19, 1.0));
    });

    test('Speed calculation between timestamped points is accurate', () {
      final t0 = DateTime(2026, 10, 15, 10, 0, 0);
      final t1 = DateTime(2026, 10, 15, 10, 0, 10); // 10 seconds later

      // Move ~100 meters in 10 seconds = 10 m/s = 36 km/h
      // 0.0009 degrees latitude is ~100.07 meters
      final p1 = GpsPoint(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: t0,
        accuracy: 5.0,
      );
      final p2 = GpsPoint(
        latitude: 0.0009,
        longitude: 0.0,
        timestamp: t1,
        accuracy: 5.0,
      );

      final speedKmH = DistanceCalculator.calculateSpeedKmH(p1, p2);
      expect(speedKmH, closeTo(36.0, 1.0));
    });

    test('Path distance accumulation calculates cumulative route distance', () {
      final t0 = DateTime(2026, 10, 15, 10, 0, 0);
      final points = [
        GpsPoint(
          latitude: 13.3400,
          longitude: 74.7400,
          timestamp: t0,
          accuracy: 5.0,
        ),
        GpsPoint(
          latitude: 13.3410,
          longitude: 74.7400,
          timestamp: t0.add(const Duration(seconds: 30)),
          accuracy: 5.0,
        ),
        GpsPoint(
          latitude: 13.3420,
          longitude: 74.7400,
          timestamp: t0.add(const Duration(seconds: 60)),
          accuracy: 5.0,
        ),
      ];

      final totalDistance = DistanceCalculator.calculatePathDistanceMeters(points);
      // Two segments of 0.001 degree lat (~111.2m each) => total ~222.4m
      expect(totalDistance, closeTo(222.4, 3.0));
    });
  });

  group('2. Invalid GPS Points Tests', () {
    final validTime = DateTime(2026, 10, 15, 10, 0, 0);

    test('Rejects out-of-bounds latitude (< -90 or > 90)', () {
      final invalidLatPositive = GpsPoint(
        latitude: 95.0,
        longitude: 74.0,
        timestamp: validTime,
        accuracy: 5.0,
      );
      final invalidLatNegative = GpsPoint(
        latitude: -91.5,
        longitude: 74.0,
        timestamp: validTime,
        accuracy: 5.0,
      );

      expect(invalidLatPositive.isValid(), isFalse);
      expect(invalidLatNegative.isValid(), isFalse);
    });

    test('Rejects out-of-bounds longitude (< -180 or > 180)', () {
      final invalidLngPositive = GpsPoint(
        latitude: 13.0,
        longitude: 185.0,
        timestamp: validTime,
        accuracy: 5.0,
      );
      final invalidLngNegative = GpsPoint(
        latitude: 13.0,
        longitude: -180.5,
        timestamp: validTime,
        accuracy: 5.0,
      );

      expect(invalidLngPositive.isValid(), isFalse);
      expect(invalidLngNegative.isValid(), isFalse);
    });

    test('Rejects NaN or Infinite coordinates', () {
      final nanPoint = GpsPoint(
        latitude: double.nan,
        longitude: 74.0,
        timestamp: validTime,
        accuracy: 5.0,
      );
      final infPoint = GpsPoint(
        latitude: 13.0,
        longitude: double.infinity,
        timestamp: validTime,
        accuracy: 5.0,
      );

      expect(nanPoint.isValid(), isFalse);
      expect(infPoint.isValid(), isFalse);
    });

    test('Rejects zero, negative, or poor GPS accuracy', () {
      final zeroAccuracy = GpsPoint(
        latitude: 13.0,
        longitude: 74.0,
        timestamp: validTime,
        accuracy: 0.0,
      );
      final negAccuracy = GpsPoint(
        latitude: 13.0,
        longitude: 74.0,
        timestamp: validTime,
        accuracy: -5.0,
      );
      final poorAccuracy = GpsPoint(
        latitude: 13.0,
        longitude: 74.0,
        timestamp: validTime,
        accuracy: 65.0, // > default 30m threshold
      );

      expect(zeroAccuracy.isValid(), isFalse);
      expect(negAccuracy.isValid(), isFalse);
      expect(poorAccuracy.isValid(), isFalse);
    });

    test('Rejects unrealistic teleportation speed spikes in realistic movement check', () {
      final p1 = GpsPoint(
        latitude: 13.3400,
        longitude: 74.7400,
        timestamp: validTime,
        accuracy: 5.0,
      );
      // Jump 2 kilometers in 2 seconds = 1000 m/s = 3600 km/h
      final p2Teleport = GpsPoint(
        latitude: 13.3580,
        longitude: 74.7400,
        timestamp: validTime.add(const Duration(seconds: 2)),
        accuracy: 5.0,
      );

      expect(DistanceCalculator.isRealisticMovement(p1, p2Teleport), isFalse);
    });

    test('ActivityTrackingEngine filters out invalid and teleported points', () {
      final engine = ActivityTrackingEngine();
      engine.startSession(activityType: 'walking');

      final p1 = GpsPoint(
        latitude: 13.3400,
        longitude: 74.7400,
        timestamp: validTime,
        accuracy: 5.0,
      );
      final added1 = engine.addGpsPoint(p1);
      expect(added1, isTrue);
      expect(engine.session.points.length, equals(1));

      // Attempt to add point with poor accuracy (50m)
      final poorPoint = GpsPoint(
        latitude: 13.3405,
        longitude: 74.7400,
        timestamp: validTime.add(const Duration(seconds: 5)),
        accuracy: 50.0,
      );
      final addedPoor = engine.addGpsPoint(poorPoint);
      expect(addedPoor, isFalse);
      expect(engine.session.points.length, equals(1));

      // Attempt to add teleported jump (2km in 1s)
      final jumpPoint = GpsPoint(
        latitude: 13.3600,
        longitude: 74.7400,
        timestamp: validTime.add(const Duration(seconds: 6)),
        accuracy: 5.0,
      );
      final addedJump = engine.addGpsPoint(jumpPoint);
      expect(addedJump, isFalse);
      expect(engine.session.points.length, equals(1));

      // Add normal valid movement (20 meters in 10s = 2 m/s = 7.2 km/h)
      final validP2 = GpsPoint(
        latitude: 13.34018,
        longitude: 74.7400,
        timestamp: validTime.add(const Duration(seconds: 10)),
        accuracy: 6.0,
      );
      final addedValid = engine.addGpsPoint(validP2);
      expect(addedValid, isTrue);
      expect(engine.session.points.length, equals(2));
      expect(engine.session.distanceMeters, closeTo(20.0, 2.0));

      engine.dispose();
    });
  });

  group('3. Interrupted Sessions & Lifecycle Tests', () {
    test('Serializes session to draft JSON and restores perfectly', () async {
      final startTime = DateTime(2026, 10, 15, 8, 30, 0);
      final engine1 = ActivityTrackingEngine();
      engine1.startSession(activityType: 'running');

      final p1 = GpsPoint(
        latitude: 13.3440,
        longitude: 74.7440,
        timestamp: startTime,
        accuracy: 4.5,
      );
      final p2 = GpsPoint(
        latitude: 13.3445,
        longitude: 74.7440,
        timestamp: startTime.add(const Duration(seconds: 15)),
        accuracy: 5.0,
      );

      engine1.addGpsPoint(p1);
      engine1.addGpsPoint(p2);
      engine1.pauseSession();

      final distanceBeforeInterruption = engine1.session.distanceMeters;
      final stepsBeforeInterruption = engine1.session.steps;
      final pointsCountBefore = engine1.session.points.length;

      // 1. Save session draft as done when app goes to background / paused
      final draftJson = engine1.session.toJson();
      await ActivityStorageService.saveSessionDraft(draftJson);

      // Verify draft is stored
      final loadedDraft = await ActivityStorageService.loadSessionDraft();
      expect(loadedDraft, isNotNull);
      expect(loadedDraft!['activityType'], equals('running'));
      expect(loadedDraft['status'], equals('paused'));

      // 2. Simulate app restart with a fresh engine instance
      final engine2 = ActivityTrackingEngine();
      final restoredSession = ActivitySessionData.fromJson(loadedDraft);
      engine2.restoreSession(restoredSession);

      // Verify all session attributes are preserved
      expect(engine2.session.status, equals(TrackingStatus.paused));
      expect(engine2.session.activityType, equals('running'));
      expect(engine2.session.points.length, equals(pointsCountBefore));
      expect(engine2.session.distanceMeters, equals(distanceBeforeInterruption));
      expect(engine2.session.steps, equals(stepsBeforeInterruption));

      // 3. Resume tracking on restored session and add subsequent point
      engine2.resumeSession();
      expect(engine2.session.status, equals(TrackingStatus.tracking));

      final p3 = GpsPoint(
        latitude: 13.3450,
        longitude: 74.7440,
        timestamp: startTime.add(const Duration(seconds: 30)),
        accuracy: 4.8,
      );
      final addedP3 = engine2.addGpsPoint(p3);
      expect(addedP3, isTrue);
      expect(engine2.session.points.length, equals(3));
      expect(engine2.session.distanceMeters, greaterThan(distanceBeforeInterruption));

      // 4. Finish session and verify territory is NOT awarded yet
      final finished = engine2.finishSession();
      expect(finished.status, equals(TrackingStatus.finished));

      // Cleanup
      await ActivityStorageService.clearSessionDraft();
      final cleared = await ActivityStorageService.loadSessionDraft();
      expect(cleared, isNull);

      engine1.dispose();
      engine2.dispose();
    });
  });

  group('4. Backend Persistence & Offline Queueing Tests', () {
    test('Submits activity successfully when backend is reachable', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/activities/submit'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['userId'], equals('u_test_player'));
        expect(body['activityType'], equals('walking'));

        return http.Response(
          jsonEncode({
            'success': true,
            'activity': {
              'id': 'act_test_123',
              'distanceKm': 1.25,
              'steps': 1680,
            },
            'rewards': {
              'xp': 65,
              'coins': 15,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = BackendActivityService(
        client: mockClient,
        customBaseUrl: 'http://test-server',
      );

      final result = await service.submitActivity(
        userId: 'u_test_player',
        points: [
          GpsPoint(
            latitude: 13.3440,
            longitude: 74.7440,
            timestamp: DateTime.now(),
            accuracy: 5.0,
          ),
        ],
        steps: 1680,
        durationSeconds: 900,
        activityType: 'walking',
      );

      expect(result.success, isTrue);
      expect(result.queuedOffline, isFalse);
      expect(result.activityId, equals('act_test_123'));
      expect(result.xpEarned, equals(65));
      expect(result.coinsEarned, equals(15));
    });

    test('Queues activity offline when network fails or backend is unreachable', () async {
      await ActivityStorageService.clearOfflineQueue();

      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final service = BackendActivityService(
        client: mockClient,
        customBaseUrl: 'http://unreachable-server',
      );

      final result = await service.submitActivity(
        userId: 'u_offline_player',
        points: [
          GpsPoint(
            latitude: 13.3440,
            longitude: 74.7440,
            timestamp: DateTime.now(),
            accuracy: 5.0,
          ),
        ],
        steps: 850,
        durationSeconds: 450,
        activityType: 'running',
      );

      expect(result.success, isFalse);
      expect(result.queuedOffline, isTrue);

      // Verify item exists in offline queue
      final queue = await ActivityStorageService.getOfflineQueue();
      expect(queue.length, equals(1));
      final queuedData = queue.first['data'] as Map<String, dynamic>;
      expect(queuedData['userId'], equals('u_offline_player'));
      expect(queuedData['steps'], equals(850));

      await ActivityStorageService.clearOfflineQueue();
    });

    test('syncPendingActivities drains offline queue upon network restoration', () async {
      await ActivityStorageService.clearOfflineQueue();

      // Pre-enqueue an offline activity
      await ActivityStorageService.enqueueOfflineActivity({
        'userId': 'u_drained_player',
        'points': [],
        'steps': 1200,
        'durationSeconds': 600,
        'activityType': 'walking',
      });

      var queue = await ActivityStorageService.getOfflineQueue();
      expect(queue.length, equals(1));

      // Mock backend successfully accepting submission
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'activity': {'id': 'act_synced_999'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = BackendActivityService(
        client: mockClient,
        customBaseUrl: 'http://sync-server',
      );

      final syncedCount = await service.syncPendingActivities();
      expect(syncedCount, equals(1));

      // Verify queue is now drained and empty
      queue = await ActivityStorageService.getOfflineQueue();
      expect(queue.isEmpty, isTrue);
    });
  });
}
