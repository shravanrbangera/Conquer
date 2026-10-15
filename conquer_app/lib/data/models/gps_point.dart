class GpsPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy; // Horizontal accuracy in meters
  final double? altitude;
  final double? speed; // Speed in m/s
  final double? heading;

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
  });

  /// Validates coordinate boundaries and accuracy threshold
  bool isValid({double maxAccuracyMeters = 30.0}) {
    if (latitude.isNaN || longitude.isNaN || accuracy.isNaN) return false;
    if (latitude.isInfinite || longitude.isInfinite || accuracy.isInfinite) {
      return false;
    }
    if (latitude < -90.0 || latitude > 90.0) return false;
    if (longitude < -180.0 || longitude > 180.0) return false;
    if (accuracy <= 0.0 || accuracy > maxAccuracyMeters) return false;
    return true;
  }

  double get speedKmH => (speed ?? 0.0) * 3.6;

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speedKmH,
      'heading': heading,
    };
  }

  factory GpsPoint.fromJson(Map<String, dynamic> json) {
    return GpsPoint(
      latitude: (json['lat'] ?? json['latitude'] as num).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      accuracy: (json['accuracy'] as num? ?? 10.0).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: json['speed'] != null
          ? (json['speed'] as num).toDouble() / 3.6
          : null,
      heading: (json['heading'] as num?)?.toDouble(),
    );
  }
}
