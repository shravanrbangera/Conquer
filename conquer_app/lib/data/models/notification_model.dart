class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'attack', 'conquest', 'achievement', 'system'
  final String title;
  final String message;
  final String? relatedTerritoryId;
  final bool read;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedTerritoryId,
    this.read = false,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? read}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      relatedTerritoryId: relatedTerritoryId,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: (json['userId'] ?? '').toString(),
      type: json['type'] as String? ?? 'system',
      title: json['title'] as String? ?? 'CONQUER Notification',
      message: json['message'] as String? ?? '',
      relatedTerritoryId: json['relatedTerritoryId'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
