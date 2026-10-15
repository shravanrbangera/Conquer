import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/territory_provider.dart';
import '../../../providers/conquest_provider.dart';
import '../../../providers/activity_tracking_provider.dart';
import '../../../shared/widgets/cyber_button.dart';
import '../widgets/real_interactive_map.dart';
import '../widgets/home_top_hud.dart';

class HomeMapScreen extends ConsumerWidget {
  const HomeMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final territoryState = ref.watch(territoryProvider);
    final conquestState = ref.watch(conquestProvider);
    final trackingState = ref.watch(activityTrackingProvider);

    final user = authState.user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasUnderAttack = territoryState.territories.any((t) => t.underAttack);

    return Scaffold(
      body: Stack(
        children: [
          // 1. FULLSCREEN REAL INTERACTIVE FLUTTER_MAP (OCCUPIES MOST OF THE SCREEN)
          Positioned.fill(
            child: RealInteractiveMap(
              territories: territoryState.territories,
              activeRoute: trackingState.routeCoordinates.isNotEmpty
                  ? trackingState.routeCoordinates
                  : conquestState.routeCoordinates,
            ),
          ),

          // 2. TOP FLOATING HUD
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  HomeTopHud(user: user),
                  if (hasUnderAttack) ...[
                    const SizedBox(height: 6),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.neonCrimson.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.neonCrimson, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonCrimson.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.neonCrimson, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'ALERT: Rival RAHUL is contesting Waterfront Enclave!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/territory'),
                            child: const Text(
                              'DEFEND',
                              style: TextStyle(
                                color: AppColors.neonCrimson,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. FLOATING BOTTOM START CONQUEST CTA BAR
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: CyberButton(
              text: 'START CONQUEST',
              icon: Icons.play_arrow_rounded,
              height: 56,
              variant: CyberButtonVariant.cyan,
              onPressed: () {
                ref.read(activityTrackingProvider.notifier).startTracking();
                ref.read(conquestProvider.notifier).startConquest();
                context.push('/active-conquest');
              },
            ),
          ),
        ],
      ),
    );
  }
}
