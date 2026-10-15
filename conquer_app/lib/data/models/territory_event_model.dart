class TerritoryEventModel {
  final String id;
  final String type; // 'conquest', 'capture', 'defense'
  final String actorId;
  final String actorName;
  final double areaKm2;
  final double stolenAreaKm2;
  final String? territoryId;
  final String message;
  final DateTime timestamp;

  const TerritoryEventModel({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    required this.areaKm2,
    this.stolenAreaKm2 = 0.0,
    this.territoryId,
    required this.message,
    required this.timestamp,
  });

  bool get isCapture => type == 'capture' || stolenAreaKm2 > 0;

  factory TerritoryEventModel.fromJson(Map<String, dynamic> json) {
    return TerritoryEventModel(
      id: json['id'] as String? ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
      type: json['type'] as String? ?? 'conquest',
      actorId: (json['actorId'] ?? '').toString(),
      actorName: json['actorName'] as String? ?? 'Commander',
      areaKm2: (json['areaKm2'] as num?)?.toDouble() ?? 0.0,
      stolenAreaKm2: (json['stolenAreaKm2'] as num?)?.toDouble() ?? 0.0,
      territoryId: json['territoryId'] as String?,
      message: json['message'] as String? ?? 'Territory expansion event recorded.',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
