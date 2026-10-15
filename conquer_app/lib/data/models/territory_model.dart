import 'package:flutter/material.dart';

class MapCoordinate {
  final double lat;
  final double lng;

  const MapCoordinate({required this.lat, required this.lng});

  double get latitude => lat;
  double get longitude => lng;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory MapCoordinate.fromJson(Map<String, dynamic> json) {
    return MapCoordinate(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class TerritoryModel {
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final Color color;
  final double areaKm2;
  final int defenseLevel;
  final String status;
  final bool underAttack;
  final List<MapCoordinate> polygonPoints;
  final List<List<MapCoordinate>> allPolygonRings;
  final DateTime createdAt;

  const TerritoryModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.color,
    required this.areaKm2,
    required this.defenseLevel,
    required this.status,
    this.underAttack = false,
    required this.polygonPoints,
    this.allPolygonRings = const [],
    required this.createdAt,
  });

  bool isOwnedBy(String userId) => ownerId == userId;

  List<MapCoordinate> get coordinates => polygonPoints;

  List<List<MapCoordinate>> get allRings =>
      allPolygonRings.isNotEmpty ? allPolygonRings : [polygonPoints];

  TerritoryModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? ownerName,
    Color? color,
    double? areaKm2,
    int? defenseLevel,
    String? status,
    bool? underAttack,
    List<MapCoordinate>? polygonPoints,
    List<List<MapCoordinate>>? allPolygonRings,
    DateTime? createdAt,
  }) {
    return TerritoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      color: color ?? this.color,
      areaKm2: areaKm2 ?? this.areaKm2,
      defenseLevel: defenseLevel ?? this.defenseLevel,
      status: status ?? this.status,
      underAttack: underAttack ?? this.underAttack,
      polygonPoints: polygonPoints ?? this.polygonPoints,
      allPolygonRings: allPolygonRings ?? this.allPolygonRings,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TerritoryModel.fromJson(Map<String, dynamic> json) {
    final rawOwner = json['ownerId'];
    final ownerIdStr = rawOwner is Map ? (rawOwner['_id'] ?? '').toString() : (rawOwner ?? '').toString();
    final ownerNameStr = json['ownerName'] as String? ?? 'Commander';

    Color parsedColor = const Color(0xFF3B82F6);
    final colorHex = json['color'] as String?;
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        final hexClean = colorHex.replaceFirst('#', '');
        parsedColor = Color(int.parse('FF$hexClean', radix: 16));
      } catch (_) {
        parsedColor = ownerIdStr.contains('rahul')
            ? const Color(0xFFEF4444)
            : const Color(0xFF3B82F6);
      }
    } else if (ownerIdStr.contains('rahul')) {
      parsedColor = const Color(0xFFEF4444);
    }

    final List<List<MapCoordinate>> rings = [];
    final geometry = json['geometry'] as Map<String, dynamic>?;

    if (geometry != null) {
      final geomType = geometry['type'] as String? ?? 'Polygon';
      final coordinates = geometry['coordinates'];

      if (geomType == 'Polygon' && coordinates is List && coordinates.isNotEmpty) {
        final ring0 = coordinates[0] as List<dynamic>;
        final List<MapCoordinate> ringPoints = [];
        for (final pt in ring0) {
          if (pt is List && pt.length >= 2) {
            // GeoJSON order is [lng, lat]
            ringPoints.add(MapCoordinate(
              lat: (pt[1] as num).toDouble(),
              lng: (pt[0] as num).toDouble(),
            ));
          }
        }
        if (ringPoints.isNotEmpty) {
          rings.add(ringPoints);
        }
      } else if (geomType == 'MultiPolygon' && coordinates is List) {
        for (final poly in coordinates) {
          if (poly is List && poly.isNotEmpty) {
            final ring0 = poly[0] as List<dynamic>;
            final List<MapCoordinate> ringPoints = [];
            for (final pt in ring0) {
              if (pt is List && pt.length >= 2) {
                ringPoints.add(MapCoordinate(
                  lat: (pt[1] as num).toDouble(),
                  lng: (pt[0] as num).toDouble(),
                ));
              }
            }
            if (ringPoints.isNotEmpty) {
              rings.add(ringPoints);
            }
          }
        }
      }
    }

    final firstRing = rings.isNotEmpty ? rings.first : <MapCoordinate>[];

    return TerritoryModel(
      id: (json['id'] ?? json['_id'] ?? 't_${DateTime.now().millisecondsSinceEpoch}').toString(),
      name: json['name'] as String? ?? '$ownerNameStr Sector',
      ownerId: ownerIdStr,
      ownerName: ownerNameStr,
      color: parsedColor,
      areaKm2: (json['areaKm2'] as num?)?.toDouble() ?? 0.0,
      defenseLevel: (json['defenseLevel'] as num?)?.toInt() ?? 3,
      status: json['status'] as String? ?? 'active',
      underAttack: json['underAttack'] as bool? ?? false,
      polygonPoints: firstRing,
      allPolygonRings: rings,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
