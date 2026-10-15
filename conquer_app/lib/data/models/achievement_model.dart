import 'package:flutter/material.dart';

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final double progress; // 0.0 to 1.0
  final bool isUnlocked;
  final int xpReward;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.isUnlocked,
    required this.xpReward,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? 'ach';
    final title = json['title'] as String? ?? 'Achievement';
    final desc = json['desc'] as String? ?? json['description'] as String? ?? '';
    final isUnlocked = json['unlocked'] as bool? ?? json['isUnlocked'] as bool? ?? false;

    IconData icon = Icons.emoji_events;
    final iconName = json['icon'] as String?;
    if (iconName == 'explore') icon = Icons.explore;
    if (iconName == 'flag') icon = Icons.flag;
    if (iconName == 'gps_fixed') icon = Icons.gps_fixed;
    if (iconName == 'directions_walk') icon = Icons.directions_walk;
    if (iconName == 'shield') icon = Icons.shield;
    if (iconName == 'local_fire_department') icon = Icons.local_fire_department;

    return AchievementModel(
      id: id,
      title: title,
      description: desc,
      icon: icon,
      progress: isUnlocked ? 1.0 : 0.0,
      isUnlocked: isUnlocked,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 100,
    );
  }
}
