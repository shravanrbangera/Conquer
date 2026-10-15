import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conquer_app/data/models/territory_model.dart';
import 'package:conquer_app/data/models/territory_event_model.dart';
import 'package:conquer_app/data/models/conquest_result_model.dart';
import 'package:conquer_app/data/models/user_model.dart';
import 'package:conquer_app/data/services/backend_territory_service.dart';
import 'package:conquer_app/data/services/backend_activity_service.dart';
import 'package:conquer_app/data/models/gps_point.dart';
import 'package:conquer_app/features/conquest_result/screens/conquest_result_screen.dart';
import 'package:conquer_app/features/territory/screens/territory_screen.dart';
import 'package:conquer_app/providers/territory_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Nearby Territory Loading & MultiPolygon Parsing Tests', () {
    test('Parses backend GeoJSON Polygon and MultiPolygon geometries accurately', () {
      final singlePolygonJson = {
        'id': 't_test_1',
        'ownerId': 'u_shravan',
        'ownerName': 'SHRAVAN',
        'color': '#3B82F6',
        'areaKm2': 1.82,
        'status': 'active',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [74.740, 13.340],
              [74.748, 13.340],
              [74.748, 13.348],
              [74.740, 13.348],
              [74.740, 13.340],
            ]
          ]
        }
      };

      final singleModel = TerritoryModel.fromJson(singlePolygonJson);
      expect(singleModel.id, 't_test_1');
      expect(singleModel.ownerName, 'SHRAVAN');
      expect(singleModel.areaKm2, 1.82);
      expect(singleModel.coordinates.length, 5);
      // GeoJSON [lng, lat] is properly converted to LatLng(lat, lng)
      expect(singleModel.coordinates.first.latitude, 13.340);
      expect(singleModel.coordinates.first.longitude, 74.740);
      expect(singleModel.allRings.length, 1);

      final multiPolygonJson = {
        'id': 't_test_multi',
        'ownerId': 'u_rahul',
        'ownerName': 'RAHUL',
        'color': '#EF4444',
        'areaKm2': 3.45,
        'status': 'active',
        'geometry': {
          'type': 'MultiPolygon',
          'coordinates': [
            // Sector 1
            [
              [
                [74.750, 13.342],
                [74.755, 13.342],
                [74.755, 13.347],
                [74.750, 13.347],
                [74.750, 13.342],
              ]
            ],
            // Sector 2 (Disconnected enclave)
            [
              [
                [74.760, 13.350],
                [74.765, 13.350],
                [74.765, 13.355],
                [74.760, 13.355],
                [74.760, 13.350],
              ]
            ]
          ]
        }
      };

      final multiModel = TerritoryModel.fromJson(multiPolygonJson);
      expect(multiModel.id, 't_test_multi');
      expect(multiModel.allRings.length, 2);
      expect(multiModel.allRings[0].length, 5);
      expect(multiModel.allRings[1].length, 5);
      expect(multiModel.allRings[1][0].latitude, 13.350);
      expect(multiModel.allRings[1][0].longitude, 74.760);
    });

    test('BackendTerritoryService fetches live nearby territories via HTTP client', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/territories/nearby')) {
          return http.Response(
            jsonEncode({
              'territories': [
                {
                  'id': 't_shravan_1',
                  'ownerId': 'u_shravan',
                  'ownerName': 'SHRAVAN',
                  'color': '#3B82F6',
                  'areaKm2': 1.82,
                  'status': 'active',
                  'geometry': {
                    'type': 'Polygon',
                    'coordinates': [
                      [
                        [74.740, 13.340],
                        [74.748, 13.340],
                        [74.748, 13.348],
                        [74.740, 13.348],
                        [74.740, 13.340],
                      ]
                    ]
                  }
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = BackendTerritoryService(client: mockClient);
      final territories = await service.fetchNearbyTerritories();

      expect(territories.length, 1);
      expect(territories[0].id, 't_shravan_1');
      expect(territories[0].ownerName, 'SHRAVAN');
    });
  });

  group('2. Conquest Result Screen & XP Rewards & Basic Achievements Tests', () {
    testWidgets('Renders ConquestResultScreen with victory banner, XP, and unlocked achievements',
        (WidgetTester tester) async {
      final conquestResult = ConquestResultModel(
        success: true,
        territoryAwarded: true,
        message: 'SHRAVAN enclosed and founded 0.052 km² of territory!',
        distanceKm: 0.42,
        durationSeconds: 280,
        steps: 560,
        areaConqueredKm2: 0.052,
        stolenEnemyAreaKm2: 0.021,
        xpEarned: 240,
        coinsEarned: 65,
        rewardBreakdown: {
          'baseDistance': 21,
          'loopEnclosure': 50,
          'conquestArea': 50,
          'rivalIncursion': 50,
        },
        unlockedAchievements: const [
          ConquestAchievement(
            id: 'empire_founded',
            title: 'Empire Founded',
            desc: 'Claim your very first territorial sector',
            icon: '👑',
            rewardXp: 250,
          ),
          ConquestAchievement(
            id: 'territory_hunter',
            title: 'Territory Hunter',
            desc: 'Slice and conquer land from an enemy player',
            icon: '⚔️',
            rewardXp: 200,
          ),
        ],
        affectedDefenders: const [
          AffectedDefender(
            defenderId: 'u_rahul',
            lostAreaKm2: 0.021,
            territoryId: 't_rahul_1',
          ),
        ],
        updatedUser: const UserModel(
          id: 'u_shravan',
          username: 'SHRAVAN',
          email: 'shravan@conquer.app',
          avatar: '⚔️',
          level: 14,
          xp: 19840,
          xpToNextLevel: 1000,
          coins: 1515,
          totalSteps: 1241060,
          totalDistanceKm: 642.92,
          totalTerritoryKm2: 24.87,
          streakDays: 28,
          playerColor: Color(0xFF3B82F6),
          title: 'WORLD CONQUEROR',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConquestResultScreen(result: conquestResult),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header and Title
      expect(find.text('TERRITORY SECURED'), findsOneWidget);
      expect(find.text('VICTORY IN SIGHT'), findsOneWidget);
      expect(find.text('SHRAVAN enclosed and founded 0.052 km² of territory!'), findsOneWidget);

      // Check Conquered Domain Banner
      expect(find.text('+0.052 km²'), findsOneWidget);
      expect(find.text('SOVEREIGNTY CLAIMED'), findsOneWidget);

      // Check Rival Incursion Alert & Stolen Area
      expect(find.text('RIVAL TERRITORY SLICED'), findsOneWidget);
      expect(find.textContaining('Captured +0.021 km² directly from enemy control!'), findsOneWidget);
      expect(find.textContaining('Rival RAHUL lost 0.021 km²'), findsOneWidget);

      // Check Telemetry Stats
      expect(find.text('0.42 km'), findsOneWidget);
      expect(find.text('560'), findsOneWidget);

      // Check Rewards & Breakdown
      expect(find.text('+240 XP'), findsOneWidget);
      expect(find.text('+65 Coins'), findsOneWidget);
      expect(find.text('Base Distance'), findsOneWidget);
      expect(find.text('Rival Incursion'), findsOneWidget);

      // Check Unlocked Achievements
      expect(find.text('ACHIEVEMENTS UNLOCKED'), findsOneWidget);
      expect(find.text('Empire Founded'), findsOneWidget);
      expect(find.text('Territory Hunter'), findsOneWidget);

      // Check Action Buttons
      expect(find.text('VIEW IN EMPIRE OVERVIEW'), findsOneWidget);
      expect(find.text('RETURN TO HOME MAP'), findsOneWidget);
    });
  });

  group('3. Territory Screen: Loading, Error, Empty & Battle Log States', () {
    testWidgets('Renders empty state when player holds 0 sectors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            territoryProvider.overrideWith(
              () => _CustomTerritoryNotifier(
                TerritoryState(territories: const [], isLoading: false),
              ),
            ),
          ],
          child: const MaterialApp(
            home: TerritoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NO SECTORS CONQUERED YET'), findsOneWidget);
      expect(find.text('START PATROL NOW'), findsOneWidget);
    });

    testWidgets('Renders error state with retry button when satellite sync fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            territoryProvider.overrideWith(
              () => _CustomTerritoryNotifier(
                const TerritoryState(
                  territories: [],
                  isLoading: false,
                  errorMessage: 'Network timeout: 504 Gateway Timeout',
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: TerritoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SATELLITE SYNC FAILED'), findsOneWidget);
      expect(find.text('RETRY SATELLITE SYNC'), findsOneWidget);
    });

    testWidgets('Renders Battle Log tab with recent conquests and attacks',
        (WidgetTester tester) async {
      final events = [
        TerritoryEventModel(
          id: 'evt_1',
          type: 'capture',
          actorId: 'u_shravan',
          actorName: 'SHRAVAN',
          areaKm2: 0.05,
          stolenAreaKm2: 0.02,
          message: 'SHRAVAN sliced & captured 0.02 km² from rival RAHUL!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        TerritoryEventModel(
          id: 'evt_2',
          type: 'conquest',
          actorId: 'u_rahul',
          actorName: 'RAHUL',
          areaKm2: 0.95,
          stolenAreaKm2: 0.0,
          message: 'RAHUL established Outpost Delta (0.95 km²).',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            territoryProvider.overrideWith(
              () => _CustomTerritoryNotifier(
                TerritoryState(
                  territories: const [],
                  events: events,
                  isLoading: false,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: TerritoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on BATTLE LOG tab
      await tester.tap(find.textContaining('BATTLE LOG'));
      await tester.pumpAndSettle();

      expect(find.text('SECTOR CAPTURE'), findsOneWidget);
      expect(find.text('SHRAVAN sliced & captured 0.02 km² from rival RAHUL!'), findsOneWidget);
      expect(find.text('NEW CONQUEST'), findsOneWidget);
      expect(find.text('RAHUL established Outpost Delta (0.95 km²).'), findsOneWidget);
    });
  });

  group('4. Multi-Account Flow & Slicing Simulation Tests', () {
    test('Simulates territory slicing and notification delivery between SHRAVAN and RAHUL', () async {
      // 1. Setup mock client simulating backend responses for SHRAVAN and RAHUL
      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path.contains('/api/auth/switch')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final targetId = body['userId'] as String;
          final isRahul = targetId.contains('rahul');

          return http.Response(
            jsonEncode({
              'success': true,
              'user': {
                'id': targetId,
                'username': isRahul ? 'RAHUL' : 'SHRAVAN',
                'email': isRahul ? 'rahul@conquer.app' : 'shravan@conquer.app',
                'avatar': isRahul ? '🛡️' : '⚔️',
                'level': isRahul ? 11 : 14,
                'xp': isRahul ? 12100 : 19600,
                'coins': isRahul ? 890 : 1450,
                'totalSteps': isRahul ? 842100 : 1240500,
                'totalDistanceKm': isRahul ? 412.0 : 642.5,
                'totalTerritoryKm2': isRahul ? 14.28 : 24.87,
                'streakDays': isRahul ? 14 : 28,
                'playerColor': isRahul ? '#EF4444' : '#3B82F6',
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.contains('/api/activities/submit')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'territoryAwarded': true,
              'activity': {
                'id': 'act_test_conquest',
                'userId': 'u_shravan',
                'type': 'walking',
                'distanceKm': 0.45,
                'durationSeconds': 320,
                'steps': 610,
                'areaConqueredKm2': 0.05,
                'capturedAreaKm2': 0.02,
                'xpEarned': 200,
                'coinsEarned': 50,
              },
              'loopResult': {
                'isValid': true,
                'reason': 'Conquest validated and territory claimed successfully.',
                'pathDistance': 450.0,
                'returnDistance': 2.5,
              },
              'conquest': {
                'newLoopAreaKm2': 0.05,
                'stolenFromEnemiesKm2': 0.02,
                'affectedDefenders': [
                  {
                    'defenderId': 'u_rahul',
                    'lostAreaKm2': 0.02,
                    'territoryId': 't_rahul_1',
                  }
                ],
              },
              'unlockedAchievements': [
                {
                  'id': 'territory_hunter',
                  'title': 'Territory Hunter',
                  'desc': 'Slice territory from an enemy player',
                  'rewardXp': 200,
                }
              ],
              'rewards': {
                'xp': 200,
                'coins': 50,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.contains('/api/notifications')) {
          final userId = request.url.queryParameters['userId'] ?? 'u_shravan';
          if (userId == 'u_rahul') {
            return http.Response(
              jsonEncode({
                'notifications': [
                  {
                    'id': 'notif_attack_rahul',
                    'userId': 'u_rahul',
                    'type': 'attack_alert',
                    'title': '⚠️ UNDER ATTACK',
                    'message': 'Commander SHRAVAN launched an attack and sliced 0.02 km² from your sector!',
                    'read': false,
                    'createdAt': DateTime.now().toIso8601String(),
                  }
                ]
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else {
            return http.Response(
              jsonEncode({
                'notifications': [
                  {
                    'id': 'notif_conquest_shravan',
                    'userId': 'u_shravan',
                    'type': 'conquest',
                    'title': '🏆 TERRITORY CONQUERED',
                    'message': 'Victory! You captured 0.02 km² from enemy territory!',
                    'read': false,
                    'createdAt': DateTime.now().toIso8601String(),
                  }
                ]
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }

        return http.Response('Not Found', 404);
      });

      final territoryService = BackendTerritoryService(client: mockClient);
      final activityService = BackendActivityService(client: mockClient);

      // STEP 1: Verify switching to SHRAVAN
      final userShravan = await territoryService.switchUser('u_shravan');
      expect(userShravan.username, 'SHRAVAN');
      expect(userShravan.id, 'u_shravan');

      // STEP 2: SHRAVAN completes a conquest loop overlapping RAHUL's territory
      final submissionResult = await activityService.submitActivity(
        userId: 'u_shravan',
        points: [
          GpsPoint(latitude: 13.3440, longitude: 74.7490, timestamp: DateTime.now(), accuracy: 5.0),
          GpsPoint(latitude: 13.3452, longitude: 74.7491, timestamp: DateTime.now(), accuracy: 5.0),
          GpsPoint(latitude: 13.3452, longitude: 74.7506, timestamp: DateTime.now(), accuracy: 5.0),
          GpsPoint(latitude: 13.3440, longitude: 74.7505, timestamp: DateTime.now(), accuracy: 5.0),
          GpsPoint(latitude: 13.3440, longitude: 74.7490, timestamp: DateTime.now(), accuracy: 5.0),
        ],
        steps: 610,
        durationSeconds: 320,
        activityType: 'walking',
      );

      expect(submissionResult.success, true);
      expect(submissionResult.territoryAwarded, true);
      expect(submissionResult.conquestResult?.areaConqueredKm2, 0.05);
      expect(submissionResult.conquestResult?.stolenEnemyAreaKm2, 0.02);
      expect(submissionResult.conquestResult?.affectedDefenders.first.defenderId, 'u_rahul');

      // STEP 3: Verify SHRAVAN's conquest victory notification
      final shravanNotifs = await territoryService.fetchNotifications('u_shravan');
      expect(shravanNotifs.length, 1);
      expect(shravanNotifs[0].title, '🏆 TERRITORY CONQUERED');
      expect(shravanNotifs[0].read, false);

      // STEP 4: Switch to victim commander RAHUL
      final userRahul = await territoryService.switchUser('u_rahul');
      expect(userRahul.username, 'RAHUL');
      expect(userRahul.id, 'u_rahul');

      // STEP 5: Verify RAHUL received an attack alert notification
      final rahulNotifs = await territoryService.fetchNotifications('u_rahul');
      expect(rahulNotifs.length, 1);
      expect(rahulNotifs[0].title, '⚠️ UNDER ATTACK');
      expect(rahulNotifs[0].message, contains('Commander SHRAVAN launched an attack and sliced 0.02 km²'));
    });
  });
}

class _CustomTerritoryNotifier extends TerritoryNotifier {
  final TerritoryState _initialState;
  _CustomTerritoryNotifier(this._initialState);

  @override
  TerritoryState build() {
    return _initialState;
  }

  @override
  Future<void> loadTerritories() async {}
}
