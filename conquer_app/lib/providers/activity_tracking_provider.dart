import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/activity_tracking_engine.dart';
import '../core/services/activity_storage_service.dart';
import '../core/services/location_service.dart';
import '../data/models/gps_point.dart';
import '../data/models/territory_model.dart';
import '../data/models/activity_model.dart';
import '../data/services/backend_activity_service.dart';
import 'activity_provider.dart';
import 'auth_provider.dart';
import 'territory_provider.dart';
import 'notification_provider.dart';

class ActivityTrackingState {
  final ActivitySessionData session;
  final bool isSubmitting;
  final String? statusMessage;
  final bool isRestoredSession;

  const ActivityTrackingState({
    this.session = const ActivitySessionData(),
    this.isSubmitting = false,
    this.statusMessage,
    this.isRestoredSession = false,
  });

  bool get isActive => session.status == TrackingStatus.tracking;
  bool get isPaused => session.status == TrackingStatus.paused;
  bool get isFinished => session.status == TrackingStatus.finished;

  List<MapCoordinate> get routeCoordinates => session.points
      .map((p) => MapCoordinate(lat: p.latitude, lng: p.longitude))
      .toList();

  ActivityTrackingState copyWith({
    ActivitySessionData? session,
    bool? isSubmitting,
    String? statusMessage,
    bool? isRestoredSession,
  }) {
    return ActivityTrackingState(
      session: session ?? this.session,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      statusMessage: statusMessage,
      isRestoredSession: isRestoredSession ?? this.isRestoredSession,
    );
  }
}

class ActivityTrackingNotifier extends Notifier<ActivityTrackingState>
    with WidgetsBindingObserver {
  late final ActivityTrackingEngine _engine;
  late final BackendActivityService _backendService;
  StreamSubscription<Position>? _gpsSubscription;

  @override
  ActivityTrackingState build() {
    _backendService = BackendActivityService();
    _engine = ActivityTrackingEngine(
      onSessionUpdate: (sessionData) {
        state = state.copyWith(session: sessionData);
      },
    );

    // Register application lifecycle listener
    WidgetsBinding.instance.addObserver(this);

    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _gpsSubscription?.cancel();
      _engine.dispose();
    });

    // Check for saved draft session from previous interruption
    Future.microtask(() => _checkForInterruptedSession());

    return const ActivityTrackingState();
  }

  // --- APPLICATION LIFECYCLE MANAGEMENT ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App was backgrounded or interrupted: persist session draft to disk immediately
      if (this.state.isActive || this.state.isPaused) {
        ActivityStorageService.saveSessionDraft(this.state.session.toJson());
      }
    } else if (state == AppLifecycleState.resumed) {
      // App returned to foreground: attempt to sync any offline activities
      _backendService.syncPendingActivities();
    }
  }

  Future<void> _checkForInterruptedSession() async {
    final draft = await ActivityStorageService.loadSessionDraft();
    if (draft != null) {
      final restoredSession = ActivitySessionData.fromJson(draft);
      if (restoredSession.status == TrackingStatus.tracking ||
          restoredSession.status == TrackingStatus.paused) {
        _engine.restoreSession(restoredSession);
        state = state.copyWith(
          session: restoredSession,
          isRestoredSession: true,
          statusMessage: 'Restored interrupted tracking session from disk.',
        );

        if (restoredSession.status == TrackingStatus.tracking) {
          _startGpsStream();
        }
      }
    }
  }

  // --- ACTIVITY CONTROLS ---

  void startTracking({String activityType = 'walking'}) {
    _engine.startSession(activityType: activityType);
    _startGpsStream();
    // Persist initial state
    ActivityStorageService.saveSessionDraft(_engine.session.toJson());
  }

  void pauseTracking() {
    _engine.pauseSession();
    _gpsSubscription?.pause();
    ActivityStorageService.saveSessionDraft(_engine.session.toJson());
  }

  void resumeTracking() {
    _engine.resumeSession();
    _gpsSubscription?.resume();
    ActivityStorageService.saveSessionDraft(_engine.session.toJson());
  }

  void _startGpsStream() {
    _gpsSubscription?.cancel();
    try {
      _gpsSubscription = LocationService.getPositionStream(
        distanceFilter: 2,
        accuracy: LocationAccuracy.high,
      ).listen(
        (position) {
          final point = GpsPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: position.timestamp,
            accuracy: position.accuracy,
            altitude: position.altitude,
            speed: position.speed,
            heading: position.heading,
          );
          _engine.addGpsPoint(point);
        },
        onError: (e) {
          state = state.copyWith(
            statusMessage: 'GPS stream error: $e',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        statusMessage: 'Failed to start GPS tracking stream: $e',
      );
    }
  }

  /// Manually add GPS point (e.g., for simulated movement or testing)
  bool recordGpsPoint(GpsPoint point) {
    return _engine.addGpsPoint(point);
  }

  /// Finishes the session, persists through the backend, queues offline on network error,
  /// and updates local activity logs.
  Future<ActivitySubmissionResult> finishTracking() async {
    _gpsSubscription?.cancel();
    final finishedSession = _engine.finishSession();

    state = state.copyWith(
      isSubmitting: true,
      statusMessage: 'Persisting session to backend...',
    );

    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? 'u_shravan';

    final result = await _backendService.submitActivity(
      userId: userId,
      points: finishedSession.points,
      steps: finishedSession.steps,
      durationSeconds: finishedSession.elapsedSeconds,
      activityType: finishedSession.activityType,
    );

    // Record to local ActivityProvider log
    final isLoop = result.territoryAwarded;
    final conqueredArea = result.conquestResult?.areaConqueredKm2 ?? 0.0;

    ref.read(activityProvider.notifier).addActivity(
          ConquestActivityModel(
            id: result.activityId ?? 'act_${DateTime.now().millisecondsSinceEpoch}',
            type: finishedSession.activityType,
            distanceKm: finishedSession.distanceKm,
            durationSeconds: finishedSession.elapsedSeconds,
            steps: finishedSession.steps,
            loopCompleted: isLoop,
            areaConqueredKm2: conqueredArea,
            trustScore: 99,
            xpEarned: result.xpEarned ?? (finishedSession.distanceKm * 50).round(),
            coinsEarned: result.coinsEarned ?? (finishedSession.distanceKm * 10).round(),
            createdAt: DateTime.now(),
          ),
        );

    // Update authenticated user stats if returned by backend
    if (result.conquestResult?.updatedUser != null) {
      ref.read(authProvider.notifier).updateUser(result.conquestResult!.updatedUser!);
    }

    // Refresh live territories & notifications upon completed claim
    if (result.territoryAwarded) {
      ref.read(territoryProvider.notifier).loadTerritories();
      ref.read(notificationProvider.notifier).loadNotifications();
    }

    // Clear saved session draft now that activity is finalized
    await ActivityStorageService.clearSessionDraft();

    state = state.copyWith(
      isSubmitting: false,
      statusMessage: result.message,
    );

    return result;
  }

  void discardTracking() async {
    _gpsSubscription?.cancel();
    _engine.reset();
    await ActivityStorageService.clearSessionDraft();
    state = const ActivityTrackingState();
  }
}

final activityTrackingProvider =
    NotifierProvider<ActivityTrackingNotifier, ActivityTrackingState>(
  ActivityTrackingNotifier.new,
);
