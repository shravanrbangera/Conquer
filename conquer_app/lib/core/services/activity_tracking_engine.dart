import 'dart:async';
import '../../data/models/gps_point.dart';
import '../utils/distance_calculator.dart';

enum TrackingStatus { idle, tracking, paused, finished }

class ActivitySessionData {
  final TrackingStatus status;
  final String activityType; // 'walking' | 'running'
  final List<GpsPoint> points;
  final double distanceMeters;
  final int elapsedSeconds;
  final int steps;
  final double currentSpeedKmH;
  final DateTime? startTime;

  const ActivitySessionData({
    this.status = TrackingStatus.idle,
    this.activityType = 'walking',
    this.points = const [],
    this.distanceMeters = 0.0,
    this.elapsedSeconds = 0,
    this.steps = 0,
    this.currentSpeedKmH = 0.0,
    this.startTime,
  });

  double get distanceKm => distanceMeters / 1000.0;

  String get durationFormatted {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'activityType': activityType,
      'points': points.map((p) => p.toJson()).toList(),
      'distanceMeters': distanceMeters,
      'elapsedSeconds': elapsedSeconds,
      'steps': steps,
      'currentSpeedKmH': currentSpeedKmH,
      'startTime': startTime?.toIso8601String(),
    };
  }

  factory ActivitySessionData.fromJson(Map<String, dynamic> json) {
    return ActivitySessionData(
      status: TrackingStatus.values.byName(json['status'] as String? ?? 'idle'),
      activityType: json['activityType'] as String? ?? 'walking',
      points: (json['points'] as List<dynamic>? ?? [])
          .map((p) => GpsPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      distanceMeters: (json['distanceMeters'] as num? ?? 0.0).toDouble(),
      elapsedSeconds: (json['elapsedSeconds'] as num? ?? 0).toInt(),
      steps: (json['steps'] as num? ?? 0).toInt(),
      currentSpeedKmH: (json['currentSpeedKmH'] as num? ?? 0.0).toDouble(),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
    );
  }
}

class ActivityTrackingEngine {
  ActivitySessionData _session = const ActivitySessionData();
  Timer? _tickerTimer;
  final void Function(ActivitySessionData)? onSessionUpdate;

  ActivityTrackingEngine({this.onSessionUpdate});

  ActivitySessionData get session => _session;

  void startSession({String activityType = 'walking'}) {
    _tickerTimer?.cancel();
    _session = ActivitySessionData(
      status: TrackingStatus.tracking,
      activityType: activityType,
      points: [],
      distanceMeters: 0.0,
      elapsedSeconds: 0,
      steps: 0,
      currentSpeedKmH: 0.0,
      startTime: DateTime.now(),
    );

    _startTimer();
    onSessionUpdate?.call(_session);
  }

  void pauseSession() {
    if (_session.status != TrackingStatus.tracking) return;
    _tickerTimer?.cancel();
    _session = ActivitySessionData(
      status: TrackingStatus.paused,
      activityType: _session.activityType,
      points: _session.points,
      distanceMeters: _session.distanceMeters,
      elapsedSeconds: _session.elapsedSeconds,
      steps: _session.steps,
      currentSpeedKmH: 0.0,
      startTime: _session.startTime,
    );
    onSessionUpdate?.call(_session);
  }

  void resumeSession() {
    if (_session.status != TrackingStatus.paused) return;
    _session = ActivitySessionData(
      status: TrackingStatus.tracking,
      activityType: _session.activityType,
      points: _session.points,
      distanceMeters: _session.distanceMeters,
      elapsedSeconds: _session.elapsedSeconds,
      steps: _session.steps,
      currentSpeedKmH: _session.currentSpeedKmH,
      startTime: _session.startTime,
    );
    _startTimer();
    onSessionUpdate?.call(_session);
  }

  /// Appends a new timestamped GPS point, applying accuracy and movement sanity checks.
  bool addGpsPoint(GpsPoint point, {double maxAccuracyMeters = 30.0}) {
    if (_session.status != TrackingStatus.tracking) return false;
    if (!point.isValid(maxAccuracyMeters: maxAccuracyMeters)) return false;

    double addedDistance = 0.0;
    double speedKmH = point.speedKmH;

    if (_session.points.isNotEmpty) {
      final lastPoint = _session.points.last;
      if (!DistanceCalculator.isRealisticMovement(lastPoint, point)) {
        return false; // Reject speed spike / jump
      }

      addedDistance = DistanceCalculator.haversineDistanceMeters(
        lastPoint.latitude,
        lastPoint.longitude,
        point.latitude,
        point.longitude,
      );

      if (speedKmH <= 0.0) {
        speedKmH = DistanceCalculator.calculateSpeedKmH(lastPoint, point);
      }
    }

    // Step estimation based on activity cadence: ~1350 steps per km
    final estimatedSteps = ((_session.distanceMeters + addedDistance) * 1.35).round();

    final updatedPoints = List<GpsPoint>.from(_session.points)..add(point);

    _session = ActivitySessionData(
      status: _session.status,
      activityType: _session.activityType,
      points: updatedPoints,
      distanceMeters: _session.distanceMeters + addedDistance,
      elapsedSeconds: _session.elapsedSeconds,
      steps: estimatedSteps,
      currentSpeedKmH: speedKmH,
      startTime: _session.startTime,
    );

    onSessionUpdate?.call(_session);
    return true;
  }

  ActivitySessionData finishSession() {
    _tickerTimer?.cancel();
    _session = ActivitySessionData(
      status: TrackingStatus.finished,
      activityType: _session.activityType,
      points: _session.points,
      distanceMeters: _session.distanceMeters,
      elapsedSeconds: _session.elapsedSeconds,
      steps: _session.steps,
      currentSpeedKmH: 0.0,
      startTime: _session.startTime,
    );
    onSessionUpdate?.call(_session);
    return _session;
  }

  void reset() {
    _tickerTimer?.cancel();
    _session = const ActivitySessionData();
    onSessionUpdate?.call(_session);
  }

  /// Restores session state from draft after application interruption.
  void restoreSession(ActivitySessionData restored) {
    _tickerTimer?.cancel();
    _session = restored;

    if (_session.status == TrackingStatus.tracking) {
      _startTimer();
    }
    onSessionUpdate?.call(_session);
  }

  void _startTimer() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_session.status == TrackingStatus.tracking) {
        _session = ActivitySessionData(
          status: _session.status,
          activityType: _session.activityType,
          points: _session.points,
          distanceMeters: _session.distanceMeters,
          elapsedSeconds: _session.elapsedSeconds + 1,
          steps: _session.steps,
          currentSpeedKmH: _session.currentSpeedKmH,
          startTime: _session.startTime,
        );
        onSessionUpdate?.call(_session);
      }
    });
  }

  void dispose() {
    _tickerTimer?.cancel();
  }
}
