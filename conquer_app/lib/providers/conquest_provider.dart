import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/territory_model.dart';

class ConquestSessionState {
  final bool isActive;
  final bool isPaused;
  final int elapsedSeconds;
  final double distanceKm;
  final int steps;
  final double currentSpeedKmH;
  final int trustScore;
  final bool isLoopClosed;
  final double distanceToStartMeters;
  final List<MapCoordinate> routeCoordinates;
  final bool isCompleted;
  final double? conqueredAreaKm2;
  final int? earnedXp;
  final int? earnedCoins;

  const ConquestSessionState({
    this.isActive = false,
    this.isPaused = false,
    this.elapsedSeconds = 0,
    this.distanceKm = 0.0,
    this.steps = 0,
    this.currentSpeedKmH = 0.0,
    this.trustScore = 99,
    this.isLoopClosed = false,
    this.distanceToStartMeters = 150.0,
    this.routeCoordinates = const [],
    this.isCompleted = false,
    this.conqueredAreaKm2,
    this.earnedXp,
    this.earnedCoins,
  });

  String get elapsedFormatted {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ConquestSessionState copyWith({
    bool? isActive,
    bool? isPaused,
    int? elapsedSeconds,
    double? distanceKm,
    int? steps,
    double? currentSpeedKmH,
    int? trustScore,
    bool? isLoopClosed,
    double? distanceToStartMeters,
    List<MapCoordinate>? routeCoordinates,
    bool? isCompleted,
    double? conqueredAreaKm2,
    int? earnedXp,
    int? earnedCoins,
  }) {
    return ConquestSessionState(
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      steps: steps ?? this.steps,
      currentSpeedKmH: currentSpeedKmH ?? this.currentSpeedKmH,
      trustScore: trustScore ?? this.trustScore,
      isLoopClosed: isLoopClosed ?? this.isLoopClosed,
      distanceToStartMeters: distanceToStartMeters ?? this.distanceToStartMeters,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      isCompleted: isCompleted ?? this.isCompleted,
      conqueredAreaKm2: conqueredAreaKm2 ?? this.conqueredAreaKm2,
      earnedXp: earnedXp ?? this.earnedXp,
      earnedCoins: earnedCoins ?? this.earnedCoins,
    );
  }
}

class ConquestNotifier extends Notifier<ConquestSessionState> {
  Timer? _timer;

  @override
  ConquestSessionState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const ConquestSessionState();
  }

  void startConquest() {
    _timer?.cancel();
    state = const ConquestSessionState(
      isActive: true,
      isPaused: false,
      elapsedSeconds: 0,
      distanceKm: 0.05,
      steps: 65,
      currentSpeedKmH: 5.4,
      trustScore: 99,
      isLoopClosed: false,
      distanceToStartMeters: 140.0,
      routeCoordinates: [
        MapCoordinate(lat: 13.344, lng: 74.744),
        MapCoordinate(lat: 13.3445, lng: 74.7445),
      ],
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isPaused && state.isActive) {
        state = state.copyWith(
          elapsedSeconds: state.elapsedSeconds + 1,
        );
      }
    });
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void simulateStep() {
    if (!state.isActive) return;

    final nextIndex = state.routeCoordinates.length;
    final simulatedPoints = [
      const MapCoordinate(lat: 13.344, lng: 74.744),
      const MapCoordinate(lat: 13.3445, lng: 74.7445),
      const MapCoordinate(lat: 13.346, lng: 74.7445),
      const MapCoordinate(lat: 13.346, lng: 74.747),
      const MapCoordinate(lat: 13.344, lng: 74.747),
      const MapCoordinate(lat: 13.34401, lng: 74.74401), // Closed loop back to start!
    ];

    if (nextIndex < simulatedPoints.length) {
      final updatedList = List<MapCoordinate>.from(state.routeCoordinates)
        ..add(simulatedPoints[nextIndex]);
      final isClosed = nextIndex == simulatedPoints.length - 1;

      state = state.copyWith(
        routeCoordinates: updatedList,
        distanceKm: state.distanceKm + 0.35,
        steps: state.steps + 420,
        currentSpeedKmH: 6.2,
        distanceToStartMeters: isClosed ? 0.0 : (140.0 - (nextIndex * 25.0)),
        isLoopClosed: isClosed,
      );
    } else {
      // Toggle loop closed
      state = state.copyWith(
        isLoopClosed: true,
        distanceToStartMeters: 0.0,
      );
    }
  }

  void completeConquest() {
    _timer?.cancel();
    state = state.copyWith(
      isActive: false,
      isCompleted: true,
      conqueredAreaKm2: 0.68,
      earnedXp: 260,
      earnedCoins: 65,
    );
  }

  void resetSession() {
    _timer?.cancel();
    state = const ConquestSessionState();
  }
}

final conquestProvider =
    NotifierProvider<ConquestNotifier, ConquestSessionState>(ConquestNotifier.new);
