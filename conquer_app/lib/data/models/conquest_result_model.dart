import 'territory_model.dart';
import 'user_model.dart';

class ConquestAchievement {
  final String id;
  final String title;
  final String desc;
  final String icon;
  final int rewardXp;

  const ConquestAchievement({
    required this.id,
    required this.title,
    required this.desc,
    this.icon = '🏅',
    this.rewardXp = 100,
  });

  factory ConquestAchievement.fromJson(Map<String, dynamic> json) {
    return ConquestAchievement(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Achievement Unlocked',
      desc: json['desc'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏅',
      rewardXp: (json['rewardXp'] as num?)?.toInt() ?? 100,
    );
  }
}

class AffectedDefender {
  final String defenderId;
  final double lostAreaKm2;
  final String territoryId;

  const AffectedDefender({
    required this.defenderId,
    required this.lostAreaKm2,
    required this.territoryId,
  });

  factory AffectedDefender.fromJson(Map<String, dynamic> json) {
    return AffectedDefender(
      defenderId: (json['defenderId'] ?? '').toString(),
      lostAreaKm2: (json['lostAreaKm2'] as num?)?.toDouble() ?? 0.0,
      territoryId: (json['territoryId'] ?? '').toString(),
    );
  }
}

class ConquestResultModel {
  final bool success;
  final bool territoryAwarded;
  final String message;
  final double distanceKm;
  final int durationSeconds;
  final int steps;
  final double areaConqueredKm2;
  final double stolenEnemyAreaKm2;
  final int xpEarned;
  final int coinsEarned;
  final Map<String, dynamic>? rewardBreakdown;
  final List<ConquestAchievement> unlockedAchievements;
  final List<AffectedDefender> affectedDefenders;
  final TerritoryModel? attackerTerritory;
  final UserModel? updatedUser;
  final List<MapCoordinate> routeCoordinates;

  const ConquestResultModel({
    required this.success,
    required this.territoryAwarded,
    required this.message,
    required this.distanceKm,
    required this.durationSeconds,
    required this.steps,
    required this.areaConqueredKm2,
    required this.stolenEnemyAreaKm2,
    required this.xpEarned,
    required this.coinsEarned,
    this.rewardBreakdown,
    this.unlockedAchievements = const [],
    this.affectedDefenders = const [],
    this.attackerTerritory,
    this.updatedUser,
    this.routeCoordinates = const [],
  });

  factory ConquestResultModel.fromJson(Map<String, dynamic> json, {List<MapCoordinate>? points}) {
    final activity = json['activity'] as Map<String, dynamic>? ?? {};
    final conquest = json['conquest'] as Map<String, dynamic>?;
    final rewards = json['rewards'] as Map<String, dynamic>? ?? {};
    final loopResult = json['loopResult'] as Map<String, dynamic>? ?? {};
    final userData = json['user'] as Map<String, dynamic>?;

    final territoryAwarded = json['territoryAwarded'] == true;
    final newLoopArea = (conquest?['newLoopAreaKm2'] as num?)?.toDouble() ??
        (activity['areaConqueredKm2'] as num?)?.toDouble() ??
        0.0;
    final stolenArea = (conquest?['stolenFromEnemiesKm2'] as num?)?.toDouble() ??
        (activity['capturedAreaKm2'] as num?)?.toDouble() ??
        0.0;

    final achievementsRaw = json['unlockedAchievements'] as List<dynamic>? ?? [];
    final achievements = achievementsRaw
        .map((a) => ConquestAchievement.fromJson(a as Map<String, dynamic>))
        .toList();

    final defendersRaw = conquest?['affectedDefenders'] as List<dynamic>? ?? [];
    final defenders = defendersRaw
        .map((d) => AffectedDefender.fromJson(d as Map<String, dynamic>))
        .toList();

    TerritoryModel? territory;
    if (conquest?['attackerTerritory'] != null) {
      territory = TerritoryModel.fromJson(conquest!['attackerTerritory'] as Map<String, dynamic>);
    }

    UserModel? user;
    if (userData != null) {
      user = UserModel.fromJson(userData);
    }

    final reason = loopResult['reason'] as String? ??
        (territoryAwarded
            ? 'Conquest validated and territory claimed successfully!'
            : 'Route recorded. Complete a closed loop over 100m to capture territory.');

    return ConquestResultModel(
      success: json['success'] == true,
      territoryAwarded: territoryAwarded,
      message: reason,
      distanceKm: (activity['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (activity['durationSeconds'] as num?)?.toInt() ?? 0,
      steps: (activity['steps'] as num?)?.toInt() ?? 0,
      areaConqueredKm2: newLoopArea,
      stolenEnemyAreaKm2: stolenArea,
      xpEarned: (rewards['xp'] as num?)?.toInt() ?? (activity['xpEarned'] as num?)?.toInt() ?? 0,
      coinsEarned: (rewards['coins'] as num?)?.toInt() ?? (activity['coinsEarned'] as num?)?.toInt() ?? 0,
      rewardBreakdown: rewards['breakdown'] as Map<String, dynamic>?,
      unlockedAchievements: achievements,
      affectedDefenders: defenders,
      attackerTerritory: territory,
      updatedUser: user,
      routeCoordinates: points ?? const [],
    );
  }
}
