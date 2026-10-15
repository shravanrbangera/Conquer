import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/services/location_service.dart';

class LocationState {
  final LocationPermissionState permissionState;
  final Position? position;
  final String? errorMessage;
  final bool isTracking;

  const LocationState({
    this.permissionState = LocationPermissionState.loading,
    this.position,
    this.errorMessage,
    this.isTracking = false,
  });

  LatLng? get latLng => position != null
      ? LatLng(position!.latitude, position!.longitude)
      : null;

  LocationState copyWith({
    LocationPermissionState? permissionState,
    Position? position,
    String? errorMessage,
    bool? isTracking,
  }) {
    return LocationState(
      permissionState: permissionState ?? this.permissionState,
      position: position ?? this.position,
      errorMessage: errorMessage,
      isTracking: isTracking ?? this.isTracking,
    );
  }
}

class LocationNotifier extends Notifier<LocationState> {
  StreamSubscription<Position>? _positionSubscription;

  @override
  LocationState build() {
    ref.onDispose(() {
      _positionSubscription?.cancel();
    });

    // Automatically check & request on init
    Future.microtask(() => refreshLocation());

    return const LocationState();
  }

  Future<void> refreshLocation() async {
    state = state.copyWith(permissionState: LocationPermissionState.loading);

    final result = await LocationService.determinePosition();
    state = state.copyWith(
      permissionState: result.state,
      position: result.position,
      errorMessage: result.errorMessage,
    );

    if (result.state == LocationPermissionState.granted) {
      _startLiveTracking();
    }
  }

  void _startLiveTracking() {
    _positionSubscription?.cancel();
    try {
      _positionSubscription = LocationService.getPositionStream(
        distanceFilter: 3,
        accuracy: LocationAccuracy.high,
      ).listen(
        (position) {
          state = state.copyWith(
            position: position,
            permissionState: LocationPermissionState.granted,
            isTracking: true,
          );
        },
        onError: (e) {
          state = state.copyWith(
            errorMessage: 'GPS stream error: $e',
          );
        },
      );
    } catch (_) {
      // Platform stream unsupported or disabled
    }
  }

  Future<void> openSettings() async {
    await LocationService.openAppSettings();
  }

  Future<void> openLocationService() async {
    await LocationService.openLocationSettings();
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
