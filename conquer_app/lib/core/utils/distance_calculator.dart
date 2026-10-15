import 'dart:math' as math;
import '../../data/models/gps_point.dart';

class DistanceCalculator {
  DistanceCalculator._();

  static const double earthRadiusMeters = 6371000.0;

  /// Haversine formula to calculate great-circle distance between two GPS coordinates in meters.
  static double haversineDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) return 0.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final rLat1 = _degreesToRadians(lat1);
    final rLat2 = _degreesToRadians(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rLat1) * math.cos(rLat2) * math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));

    return earthRadiusMeters * c;
  }

  /// Calculates speed in km/h between two timestamped points.
  static double calculateSpeedKmH(GpsPoint p1, GpsPoint p2) {
    final distanceMeters = haversineDistanceMeters(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );

    final durationSeconds = (p2.timestamp.difference(p1.timestamp).inMilliseconds.abs()) / 1000.0;
    if (durationSeconds <= 0.1) return 0.0;

    final speedMetersPerSecond = distanceMeters / durationSeconds;
    return speedMetersPerSecond * 3.6;
  }

  /// Validates whether the transition between two points represents realistic human movement.
  static bool isRealisticMovement(
    GpsPoint p1,
    GpsPoint p2, {
    double maxSpeedKmH = 35.0,
  }) {
    if (!p1.isValid() || !p2.isValid()) return false;

    final durationSeconds = (p2.timestamp.difference(p1.timestamp).inMilliseconds.abs()) / 1000.0;
    
    // If points are within 0.2s of each other and distance is significant (> 5m), likely a jump
    final dist = haversineDistanceMeters(p1.latitude, p1.longitude, p2.latitude, p2.longitude);
    if (durationSeconds < 0.2 && dist > 5.0) return false;

    // Check maximum speed threshold
    final speed = calculateSpeedKmH(p1, p2);
    if (speed > maxSpeedKmH) return false;

    return true;
  }

  /// Calculates total accumulated distance along a route, filtering out invalid points and speed jumps.
  static double calculatePathDistanceMeters(
    List<GpsPoint> points, {
    double maxAccuracy = 30.0,
    double maxSpeedKmH = 35.0,
  }) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    GpsPoint? lastValidPoint;

    for (final point in points) {
      if (!point.isValid(maxAccuracyMeters: maxAccuracy)) continue;

      if (lastValidPoint == null) {
        lastValidPoint = point;
        continue;
      }

      if (isRealisticMovement(lastValidPoint, point, maxSpeedKmH: maxSpeedKmH)) {
        totalDistance += haversineDistanceMeters(
          lastValidPoint.latitude,
          lastValidPoint.longitude,
          point.latitude,
          point.longitude,
        );
        lastValidPoint = point;
      }
    }

    return totalDistance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
