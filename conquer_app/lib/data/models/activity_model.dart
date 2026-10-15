class ConquestActivityModel {
  final String id;
  final String type; // 'walking' | 'running'
  final double distanceKm;
  final int durationSeconds;
  final int steps;
  final bool loopCompleted;
  final double areaConqueredKm2;
  final int trustScore; // 0-100
  final int xpEarned;
  final int coinsEarned;
  final DateTime createdAt;

  const ConquestActivityModel({
    required this.id,
    required this.type,
    required this.distanceKm,
    required this.durationSeconds,
    required this.steps,
    required this.loopCompleted,
    required this.areaConqueredKm2,
    required this.trustScore,
    required this.xpEarned,
    required this.coinsEarned,
    required this.createdAt,
  });

  String get durationFormatted {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get averagePaceMinutesPerKm {
    if (distanceKm <= 0) return 0.0;
    return (durationSeconds / 60.0) / distanceKm;
  }
}
