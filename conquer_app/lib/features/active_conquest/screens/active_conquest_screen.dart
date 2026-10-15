import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/activity_tracking_engine.dart';
import '../../../data/models/gps_point.dart';
import '../../../data/services/backend_activity_service.dart';
import '../../../providers/activity_tracking_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/territory_provider.dart';
import '../../../shared/widgets/cyber_button.dart';
import '../../../shared/widgets/cyber_card.dart';
import '../../../shared/widgets/cyber_badge.dart';
import '../../home_map/widgets/real_interactive_map.dart';

class ActiveConquestScreen extends ConsumerStatefulWidget {
  const ActiveConquestScreen({super.key});

  @override
  ConsumerState<ActiveConquestScreen> createState() =>
      _ActiveConquestScreenState();
}

class _ActiveConquestScreenState extends ConsumerState<ActiveConquestScreen> {
  int _simulationIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(activityTrackingProvider);
      // Auto-start if idle
      if (state.session.status == TrackingStatus.idle) {
        ref.read(activityTrackingProvider.notifier).startTracking(
              activityType: 'walking',
            );
      }
    });
  }

  void _simulateNextPoint() {
    final locationState = ref.read(locationProvider);
    final baseLat = locationState.latLng?.latitude ?? 13.3440;
    final baseLng = locationState.latLng?.longitude ?? 74.7440;

    _simulationIndex++;
    // Simulate walking roughly ~30-40 meters per step in a polygon loop
    final latOffsets = [0.0, 0.0003, 0.0006, 0.0006, 0.0003, 0.0000];
    final lngOffsets = [0.0, 0.0001, 0.0002, 0.0005, 0.0005, 0.0000];

    final idx = _simulationIndex % latOffsets.length;
    final simulatedPoint = GpsPoint(
      latitude: baseLat + latOffsets[idx],
      longitude: baseLng + lngOffsets[idx],
      timestamp: DateTime.now(),
      accuracy: 6.5,
      speed: 1.45, // ~5.2 km/h
      altitude: 18.0,
      heading: 45.0,
    );

    final accepted =
        ref.read(activityTrackingProvider.notifier).recordGpsPoint(simulatedPoint);

    if (!accepted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulated point rejected by GPS engine sanity filter.'),
          backgroundColor: AppColors.neonCrimson,
          duration: Duration(milliseconds: 1200),
        ),
      );
    }
  }

  void _simulateClosedLoop({bool raidRival = true}) {
    final locationState = ref.read(locationProvider);
    final baseLat = raidRival ? 13.3440 : (locationState.latLng?.latitude ?? 13.3440);
    final baseLng = raidRival ? 74.7490 : (locationState.latLng?.longitude ?? 74.7440);

    final now = DateTime.now();
    // 6 coordinates forming a 400m perimeter loop
    final loopOffsets = [
      [0.0, 0.0],
      [0.0012, 0.0001],
      [0.0012, 0.0016],
      [0.0000, 0.0015],
      [-0.00005, 0.00005],
    ];

    for (int i = 0; i < loopOffsets.length; i++) {
      final p = GpsPoint(
        latitude: baseLat + loopOffsets[i][0],
        longitude: baseLng + loopOffsets[i][1],
        timestamp: now.subtract(Duration(seconds: (loopOffsets.length - i) * 35)),
        accuracy: 4.5,
        speed: 1.4,
        altitude: 15.0,
      );
      ref.read(activityTrackingProvider.notifier).recordGpsPoint(p);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Closed loop recorded (> 100m). Tap CLAIM to submit to CONQUER engine!'),
          backgroundColor: AppColors.neonEmerald,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCompletionModal(
    BuildContext context,
    ActivitySessionData session,
    ActivitySubmissionResult result,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isQueued = result.queuedOffline;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: CyberCard(
            borderColor: isQueued ? AppColors.neonGold : AppColors.neonEmerald,
            isGlowing: true,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy or Offline Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isQueued ? AppColors.neonGold : AppColors.neonEmerald)
                        .withValues(alpha: 0.2),
                    border: Border.all(
                      color: isQueued ? AppColors.neonGold : AppColors.neonEmerald,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isQueued ? Icons.cloud_off_rounded : Icons.check_circle_rounded,
                    color: isQueued ? AppColors.neonGold : AppColors.neonEmerald,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  isQueued ? 'ACTIVITY SAVED OFFLINE' : 'SESSION RECORDED!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.message ?? 'GPS telemetry processed successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isQueued ? AppColors.neonGold : AppColors.neonEmerald,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),

                // Stats breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill(
                      'DISTANCE',
                      '${session.distanceKm.toStringAsFixed(2)} km',
                      AppColors.neonCyan,
                    ),
                    _buildStatPill(
                      'TIME',
                      session.durationFormatted,
                      AppColors.neonGold,
                    ),
                    _buildStatPill(
                      'STEPS',
                      '${session.steps}',
                      AppColors.neonEmerald,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Territory engine status disclaimer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 16, color: AppColors.textMuted),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Territory expansion engine deferred in this tracking phase.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                CyberButton(
                  text: 'RETURN TO HOME MAP',
                  icon: Icons.check,
                  variant: isQueued
                      ? CyberButtonVariant.gold
                      : CyberButtonVariant.emerald,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/home');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(activityTrackingProvider);
    final territoryState = ref.watch(territoryProvider);
    final trackingNotifier = ref.read(activityTrackingProvider.notifier);
    final session = trackingState.session;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // 1. Live Real Interactive Map with live GPS route polyline & markers
          Positioned.fill(
            child: RealInteractiveMap(
              territories: territoryState.territories,
              activeRoute: trackingState.routeCoordinates,
            ),
          ),

          // 2. Top Status HUD & Exit
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Live GPS Tracking Beacon
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: trackingState.isPaused
                                  ? AppColors.neonGold
                                  : AppColors.neonEmerald,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: trackingState.isPaused
                                      ? AppColors.neonGold
                                      : AppColors.neonEmerald,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                trackingState.isPaused
                                    ? 'PAUSED'
                                    : 'CONQUEST ACTIVE',
                                style: TextStyle(
                                  color: trackingState.isPaused
                                      ? AppColors.neonGold
                                      : AppColors.neonEmerald,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // GPS Points Pill
                        CyberBadge(
                          label: '${session.points.length} GPS PTS',
                          icon: Icons.gps_fixed,
                          color: AppColors.neonCyan,
                        ),

                        // Cancel / Discard Session
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            trackingNotifier.discardTracking();
                            context.pop();
                          },
                        ),
                      ],
                    ),

                    // Restored Session Banner or Status Message
                    if (trackingState.statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: trackingState.isRestoredSession
                                ? AppColors.neonCyan
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          trackingState.statusMessage!,
                          style: TextStyle(
                            color: trackingState.isRestoredSession
                                ? AppColors.neonCyan
                                : Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Metrics Dashboard & Controls
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live Metrics Panel
                  CyberCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricColumn(
                          'TIME',
                          session.durationFormatted,
                          Icons.timer_outlined,
                        ),
                        _buildMetricColumn(
                          'DISTANCE',
                          '${session.distanceKm.toStringAsFixed(2)} km',
                          Icons.straighten,
                        ),
                        _buildMetricColumn(
                          'SPEED',
                          '${session.currentSpeedKmH.toStringAsFixed(1)} km/h',
                          Icons.speed,
                        ),
                        _buildMetricColumn(
                          'STEPS',
                          '${session.steps}',
                          Icons.directions_walk,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Actions row: Simulate GPS, Pause/Resume, Finish
                  Row(
                    children: [
                      // Simulate Step / Loop Button with Dropdown/Longpress or direct
                      Expanded(
                        child: CyberButton(
                          text: 'SIM STEP',
                          icon: Icons.directions_walk,
                          variant: CyberButtonVariant.outline,
                          onPressed: trackingState.isPaused
                              ? null
                              : _simulateNextPoint,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Simulate Complete Closed Loop Button
                      Expanded(
                        child: CyberButton(
                          text: 'SIM LOOP',
                          icon: Icons.all_inclusive,
                          variant: CyberButtonVariant.emerald,
                          onPressed: trackingState.isPaused
                              ? null
                              : () => _simulateClosedLoop(raidRival: true),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Pause / Resume Toggle
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgSurface,
                          border: Border.all(
                            color: trackingState.isPaused
                                ? AppColors.neonEmerald
                                : AppColors.neonGold,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            trackingState.isPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                            color: trackingState.isPaused
                                ? AppColors.neonEmerald
                                : AppColors.neonGold,
                          ),
                          onPressed: () {
                            if (trackingState.isPaused) {
                              trackingNotifier.resumeTracking();
                            } else {
                              trackingNotifier.pauseTracking();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Finish / Claim Session Button
                      Expanded(
                        child: CyberButton(
                          text: trackingState.isSubmitting
                              ? 'CLAIMING...'
                              : 'CLAIM',
                          icon: Icons.flag,
                          variant: CyberButtonVariant.cyan,
                          isLoading: trackingState.isSubmitting,
                          onPressed: trackingState.isSubmitting
                              ? null
                              : () async {
                                  final result =
                                      await trackingNotifier.finishTracking();
                                  if (context.mounted) {
                                    if (result.conquestResult != null) {
                                      context.go('/conquest-result',
                                          extra: result.conquestResult);
                                    } else {
                                      _showCompletionModal(
                                          context, session, result);
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

