import 'package:geolocator/geolocator.dart';

enum LocationPermissionState {
  loading,
  serviceDisabled,
  denied,
  deniedForever,
  granted,
  error,
}

class LocationResult {
  final LocationPermissionState state;
  final Position? position;
  final String? errorMessage;

  const LocationResult({
    required this.state,
    this.position,
    this.errorMessage,
  });
}

class LocationService {
  LocationService._();

  /// Check location services and permissions, returning current position if granted.
  static Future<LocationResult> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled.
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return LocationResult(
        state: LocationPermissionState.error,
        errorMessage: 'Unable to check location service status: $e',
      );
    }

    if (!serviceEnabled) {
      return const LocationResult(
        state: LocationPermissionState.serviceDisabled,
        errorMessage: 'Device Location Services are disabled.',
      );
    }

    // 2. Check permission status.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          state: LocationPermissionState.denied,
          errorMessage: 'Location permissions were denied by the user.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        state: LocationPermissionState.deniedForever,
        errorMessage:
            'Location permissions are permanently denied. Please enable them in app settings.',
      );
    }

    // 3. Permissions are granted; acquire current location.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(
        state: LocationPermissionState.granted,
        position: position,
      );
    } catch (e) {
      // Fallback: try getting last known position if immediate GPS lock timed out
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LocationResult(
          state: LocationPermissionState.granted,
          position: lastKnown,
        );
      }
      return LocationResult(
        state: LocationPermissionState.error,
        errorMessage: 'Failed to acquire GPS fix: $e',
      );
    }
  }

  /// Open Android/iOS system location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings in OS settings menu
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Listen to live location updates
  static Stream<Position> getPositionStream({
    int distanceFilter = 2,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
