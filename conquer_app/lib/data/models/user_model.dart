import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String avatar;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int coins;
  final int totalSteps;
  final double totalDistanceKm;
  final double totalTerritoryKm2;
  final int streakDays;
  final Color playerColor;
  final String title;
  final List<String> achievements;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.avatar,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.coins,
    required this.totalSteps,
    required this.totalDistanceKm,
    required this.totalTerritoryKm2,
    required this.streakDays,
    required this.playerColor,
    required this.title,
    this.achievements = const [],
  });

  double get xpProgress => xpToNextLevel > 0 ? (xp % 1000) / 1000.0 : 1.0;

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? avatar,
    int? level,
    int? xp,
    int? xpToNextLevel,
    int? coins,
    int? totalSteps,
    double? totalDistanceKm,
    double? totalTerritoryKm2,
    int? streakDays,
    Color? playerColor,
    String? title,
    List<String>? achievements,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      coins: coins ?? this.coins,
      totalSteps: totalSteps ?? this.totalSteps,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalTerritoryKm2: totalTerritoryKm2 ?? this.totalTerritoryKm2,
      streakDays: streakDays ?? this.streakDays,
      playerColor: playerColor ?? this.playerColor,
      title: title ?? this.title,
      achievements: achievements ?? this.achievements,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFF3B82F6);
    final colorHex = json['playerColor'] as String?;
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        final clean = colorHex.replaceFirst('#', '');
        parsedColor = Color(int.parse('FF$clean', radix: 16));
      } catch (_) {}
    } else if ((json['id'] ?? '').toString().contains('rahul')) {
      parsedColor = const Color(0xFFEF4444);
    }

    final level = (json['level'] as num?)?.toInt() ?? 1;
    final xp = (json['xp'] as num?)?.toInt() ?? 0;
    final nextLevelXp = level * level * 100;
    final currentLevelMinXp = (level - 1) * (level - 1) * 100;
    final xpToNext = nextLevelXp - currentLevelMinXp;

    final titles = [
      'Newcomer',
      'Walker',
      'Explorer',
      'Conqueror',
      'Warrior',
      'Territory Hunter',
      'Land Master',
      'Champion',
      'Legend',
      'WORLD CONQUEROR'
    ];
    final title = (level >= 1 && level <= titles.length)
        ? titles[level - 1]
        : 'WORLD CONQUEROR';

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? 'u_shravan').toString(),
      username: json['username'] as String? ?? 'Commander',
      email: json['email'] as String? ?? 'player@conquer.app',
      avatar: json['avatar'] as String? ?? '⚔️',
      level: level,
      xp: xp,
      xpToNextLevel: xpToNext > 0 ? xpToNext : 1000,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      totalTerritoryKm2: (json['totalTerritoryKm2'] as num?)?.toDouble() ?? 0.0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 1,
      playerColor: parsedColor,
      title: title,
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
