import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/conquest_result_model.dart';
import '../../../shared/widgets/cyber_button.dart';
import '../../../shared/widgets/cyber_card.dart';
import '../../../shared/widgets/cyber_badge.dart';

class ConquestResultScreen extends ConsumerWidget {
  final ConquestResultModel result;

  const ConquestResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWon = result.territoryAwarded;
    final primaryColor = isWon ? AppColors.neonEmerald : AppColors.neonGold;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isWon ? 'TERRITORY SECURED' : 'PATROL COMPLETED',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Trophy / Shield Indicator
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: 0.15),
                    border: Border.all(color: primaryColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isWon ? (result.stolenEnemyAreaKm2 > 0 ? '⚔️' : '👑') : '🧭',
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Backend Authoritative Reason
              Text(
                isWon ? 'VICTORY IN SIGHT' : 'RECON TELEMETRY LOGGED',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isWon ? AppColors.neonCyan : AppColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Main Conquest Banner (if territory was awarded)
              if (isWon) ...[
                CyberCard(
                  borderColor: AppColors.neonEmerald,
                  isGlowing: true,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CONQUERED DOMAIN',
                            style: TextStyle(
                              color: AppColors.neonEmerald,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          CyberBadge(
                            label: 'SOVEREIGNTY CLAIMED',
                            color: AppColors.neonEmerald,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '+${result.areaConqueredKm2.toStringAsFixed(3)} km²',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Approx. ${(result.areaConqueredKm2 * 1000000).toStringAsFixed(0)} m² incorporated into your empire',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Rival Incursion / Sliced Sector Banner
              if (result.stolenEnemyAreaKm2 > 0) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.neonCrimson.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.neonCrimson, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCrimson.withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.flash_on, color: AppColors.neonCrimson, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'RIVAL TERRITORY SLICED',
                            style: TextStyle(
                              color: AppColors.neonCrimson,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Captured +${result.stolenEnemyAreaKm2.toStringAsFixed(3)} km² directly from enemy control!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      for (final defender in result.affectedDefenders) ...[
                        const SizedBox(height: 4),
                        Text(
                          '• Rival ${defender.defenderId.replaceAll('u_', '').toUpperCase()} lost ${defender.lostAreaKm2.toStringAsFixed(3)} km².',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Activity Telemetry Summary Card
              CyberCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('DISTANCE', '${result.distanceKm.toStringAsFixed(2)} km', AppColors.neonCyan),
                    _buildStatCol('TIME', _formatSeconds(result.durationSeconds), AppColors.neonGold),
                    _buildStatCol('STEPS', '${result.steps}', AppColors.neonEmerald),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Rewards & XP Progression Card
              CyberCard(
                borderColor: AppColors.neonGold.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SPOILS & REWARDS',
                          style: TextStyle(
                            color: AppColors.neonGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Row(
                          children: [
                            CyberBadge(label: '+${result.xpEarned} XP', color: AppColors.neonCyan),
                            const SizedBox(width: 6),
                            CyberBadge(label: '+${result.coinsEarned} Coins', color: AppColors.neonGold),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Rewards breakdown chips
                    if (result.rewardBreakdown != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if ((result.rewardBreakdown!['baseDistance'] ?? 0) > 0)
                            _buildBreakdownChip('Base Distance', '+${result.rewardBreakdown!['baseDistance']} XP'),
                          if ((result.rewardBreakdown!['loopEnclosure'] ?? 0) > 0)
                            _buildBreakdownChip('Loop Closed', '+${result.rewardBreakdown!['loopEnclosure']} XP'),
                          if ((result.rewardBreakdown!['conquestArea'] ?? 0) > 0)
                            _buildBreakdownChip('Territory Bonus', '+${result.rewardBreakdown!['conquestArea']} XP'),
                          if ((result.rewardBreakdown!['rivalIncursion'] ?? 0) > 0)
                            _buildBreakdownChip('Rival Incursion', '+${result.rewardBreakdown!['rivalIncursion']} XP'),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Current User Progression Bar
                    if (result.updatedUser != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LEVEL ${result.updatedUser!.level} COMMANDER',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${result.updatedUser!.xp} Total XP',
                            style: const TextStyle(
                              color: AppColors.neonCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: result.updatedUser!.xpProgress,
                          backgroundColor: AppColors.bgSurface,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Unlocked Achievements Section (if any)
              if (result.unlockedAchievements.isNotEmpty) ...[
                const Text(
                  'ACHIEVEMENTS UNLOCKED',
                  style: TextStyle(
                    color: AppColors.neonGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                for (final ach in result.unlockedAchievements) ...[
                  CyberCard(
                    borderColor: AppColors.neonGold,
                    isGlowing: true,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(ach.icon, style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ach.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ach.desc,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CyberBadge(
                          label: '+${ach.rewardXp} XP',
                          color: AppColors.neonGold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 6),
              ],

              // Action Buttons
              const SizedBox(height: 16),
              CyberButton(
                text: 'VIEW IN EMPIRE OVERVIEW',
                icon: Icons.shield,
                variant: CyberButtonVariant.cyan,
                width: double.infinity,
                onPressed: () {
                  context.go('/territory');
                },
              ),
              const SizedBox(height: 10),
              CyberButton(
                text: 'RETURN TO HOME MAP',
                icon: Icons.map,
                variant: CyberButtonVariant.emerald,
                width: double.infinity,
                onPressed: () {
                  context.go('/home');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBreakdownChip(String title, String bonus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(width: 6),
          Text(
            bonus,
            style: const TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}
