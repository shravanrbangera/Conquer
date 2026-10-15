import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/activity_provider.dart';
import '../../../shared/widgets/cyber_card.dart';
import '../../../shared/widgets/cyber_badge.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(activityProvider);
    final activities = activityState.filteredActivities;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text(
          'ACTIVITY LOGS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Metric Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CyberCard(
                borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat(
                      'TOTAL KM',
                      activityState.totalDistanceKm.toStringAsFixed(1),
                      AppColors.neonCyan,
                    ),
                    _buildSummaryStat(
                      'TOTAL STEPS',
                      '${(activityState.totalSteps / 1000).toStringAsFixed(1)}k',
                      AppColors.neonGold,
                    ),
                    _buildSummaryStat(
                      'CONQUERED',
                      '${activityState.totalAreaConquered.toStringAsFixed(1)}km²',
                      AppColors.neonEmerald,
                    ),
                  ],
                ),
              ),
            ),

            // Filter Tabs (All / Running / Walking)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip(
                    ref,
                    'ALL MISSIONS',
                    ActivityFilter.all,
                    activityState.filter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    ref,
                    'RUNNING',
                    ActivityFilter.running,
                    activityState.filter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    ref,
                    'WALKING',
                    ActivityFilter.walking,
                    activityState.filter,
                  ),
                ],
              ),
            ),

            // Activity History List
            Expanded(
              child: activities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_run, size: 48, color: AppColors.textDim),
                          const SizedBox(height: 12),
                          const Text(
                            'No activities logged yet',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: activities.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final act = activities[index];
                        final isRunning = act.type == 'running';

                        return CyberCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: act.loopCompleted
                              ? AppColors.neonEmerald.withValues(alpha: 0.25)
                              : AppColors.borderSubtle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Top Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isRunning
                                              ? AppColors.neonCrimson.withValues(alpha: 0.2)
                                              : AppColors.neonCyan.withValues(alpha: 0.2),
                                        ),
                                        child: Icon(
                                          isRunning
                                              ? Icons.directions_run
                                              : Icons.directions_walk,
                                          color: isRunning
                                              ? AppColors.neonCrimson
                                              : AppColors.neonCyan,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        isRunning ? 'TACTICAL SPRINT' : 'SECTOR RECON PATROL',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  CyberBadge(
                                    label: '${act.trustScore}% Trust',
                                    icon: Icons.shield_outlined,
                                    color: AppColors.neonCyan,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Metrics Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildCardMetric(
                                      'DISTANCE', '${act.distanceKm.toStringAsFixed(2)} km'),
                                  _buildCardMetric('DURATION', act.durationFormatted),
                                  _buildCardMetric('STEPS', '${act.steps}'),
                                  _buildCardMetric(
                                    'CLAIMED',
                                    '+${act.areaConqueredKm2.toStringAsFixed(2)} km²',
                                    color: AppColors.neonEmerald,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Card Footer Rewards
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.bgDeep,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.bolt,
                                            size: 14, color: AppColors.neonGold),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+${act.xpEarned} XP',
                                          style: const TextStyle(
                                            color: AppColors.neonGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Icon(Icons.monetization_on,
                                            size: 14, color: AppColors.neonGold),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+${act.coinsEarned} Coins',
                                          style: const TextStyle(
                                            color: AppColors.neonGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Loop ${act.loopCompleted ? 'Closed ✓' : 'Incomplete'}',
                                      style: TextStyle(
                                        color: act.loopCompleted
                                            ? AppColors.neonEmerald
                                            : AppColors.textDim,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildFilterChip(
    WidgetRef ref,
    String label,
    ActivityFilter filterValue,
    ActivityFilter currentFilter,
  ) {
    final isSelected = filterValue == currentFilter;

    return GestureDetector(
      onTap: () => ref.read(activityProvider.notifier).setFilter(filterValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonCyan.withValues(alpha: 0.2)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.neonCyan : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.neonCyan : AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCardMetric(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
