import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/sources/mock_data.dart';
import '../../../shared/widgets/cyber_card.dart';
import '../../../shared/widgets/cyber_badge.dart';
import '../../../shared/widgets/cyber_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _highPrecisionGps = true;
  bool _attackAlerts = true;
  bool _haptics = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text(
          'COMMANDER DOSSIER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Commander Header Card
            CyberCard(
              borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
              isGlowing: true,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonBlue.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.neonCyan, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan.withValues(alpha: 0.35),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(user.avatar, style: const TextStyle(fontSize: 36)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CyberBadge(
                        label: 'LEVEL ${user.level}',
                        color: AppColors.neonCyan,
                        isFilled: true,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.title,
                        style: const TextStyle(
                          color: AppColors.neonCyan,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // XP Progression Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PROGRESSION XP',
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${user.xp} / ${user.xpToNextLevel} XP',
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
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: user.xpProgress,
                          minHeight: 8,
                          backgroundColor: AppColors.bgDeep,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lifetime Stats Grid
            const Text(
              'LIFETIME RECON METRICS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildStatTile(
                  'TOTAL STEPS',
                  '${(user.totalSteps / 1000).toStringAsFixed(1)}k',
                  Icons.directions_walk,
                  AppColors.neonGold,
                ),
                _buildStatTile(
                  'DISTANCE',
                  '${user.totalDistanceKm} km',
                  Icons.straighten,
                  AppColors.neonCyan,
                ),
                _buildStatTile(
                  'TERRITORY',
                  '${user.totalTerritoryKm2} km²',
                  Icons.map,
                  AppColors.neonBlue,
                ),
                _buildStatTile(
                  'STREAK',
                  '${user.streakDays} Days 🔥',
                  Icons.local_fire_department,
                  AppColors.neonCrimson,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Achievements Showcase
            const Text(
              'HONORS & ACHIEVEMENTS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            for (final ach in MockData.achievements) ...[
              CyberCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ach.isUnlocked
                            ? AppColors.neonGold.withValues(alpha: 0.15)
                            : AppColors.bgDeep,
                        border: Border.all(
                          color: ach.isUnlocked
                              ? AppColors.neonGold
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Icon(
                        ach.icon,
                        color: ach.isUnlocked
                            ? AppColors.neonGold
                            : AppColors.textDim,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ach.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '+${ach.xpReward} XP',
                                style: const TextStyle(
                                  color: AppColors.neonGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ach.description,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),

            // System Toggles & Settings
            const Text(
              'RECON TERMINAL SETTINGS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            CyberCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('High-Precision GPS Sampling',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: const Text('1Hz polling during active loops',
                        style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                    value: _highPrecisionGps,
                    activeThumbColor: AppColors.neonCyan,
                    onChanged: (val) => setState(() => _highPrecisionGps = val),
                  ),
                  const Divider(color: AppColors.borderSubtle),
                  SwitchListTile(
                    title: const Text('Territory Attack Push Alerts',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: const Text('Notify when rival players contest your zones',
                        style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                    value: _attackAlerts,
                    activeThumbColor: AppColors.neonCyan,
                    onChanged: (val) => setState(() => _attackAlerts = val),
                  ),
                  const Divider(color: AppColors.borderSubtle),
                  SwitchListTile(
                    title: const Text('Tactile Haptic Feedback',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: const Text('Vibrate upon GPS loop closure',
                        style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                    value: _haptics,
                    activeThumbColor: AppColors.neonCyan,
                    onChanged: (val) => setState(() => _haptics = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 20),

            // Commander Switcher Section (Multi-user test support)
            const Text(
              'COMMANDER ACCOUNTS (ACTIVE FACTION)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            CyberCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ListTile(
                    leading: const Text('⚔️', style: TextStyle(fontSize: 24)),
                    title: const Text(
                      'SHRAVAN (Vanguard)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Faction Color: Neon Blue',
                        style: TextStyle(color: AppColors.neonBlue, fontSize: 11)),
                    trailing: user.id == 'u_shravan'
                        ? const CyberBadge(label: 'ACTIVE', color: AppColors.neonCyan)
                        : CyberButton(
                            text: 'SWITCH',
                            height: 32,
                            variant: CyberButtonVariant.cyan,
                            onPressed: () {
                              ref.read(authProvider.notifier).switchAccount('u_shravan');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Switched to Commander SHRAVAN (Vanguard).'),
                                  backgroundColor: AppColors.bgSurface,
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(color: AppColors.borderSubtle),
                  ListTile(
                    leading: const Text('🛡️', style: TextStyle(fontSize: 24)),
                    title: const Text(
                      'RAHUL (Shadow Syndicate)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Faction Color: Neon Crimson',
                        style: TextStyle(color: AppColors.neonCrimson, fontSize: 11)),
                    trailing: user.id == 'u_rahul'
                        ? const CyberBadge(label: 'ACTIVE', color: AppColors.neonCrimson)
                        : CyberButton(
                            text: 'SWITCH',
                            height: 32,
                            variant: CyberButtonVariant.crimson,
                            onPressed: () {
                              ref.read(authProvider.notifier).switchAccount('u_rahul');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Switched to Commander RAHUL (Shadow Syndicate).'),
                                  backgroundColor: AppColors.bgSurface,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            CyberButton(
              text: 'DE-AUTHORIZE TERMINAL',
              icon: Icons.logout,
              variant: CyberButtonVariant.outline,
              width: double.infinity,
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/auth');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
      String label, String value, IconData icon, Color accentColor) {
    return CyberCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textDim, fontSize: 10),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
