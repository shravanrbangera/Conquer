import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/territory_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/cyber_card.dart';
import '../../../shared/widgets/cyber_badge.dart';
import '../../../shared/widgets/cyber_button.dart';

class TerritoryScreen extends ConsumerStatefulWidget {
  const TerritoryScreen({super.key});

  @override
  ConsumerState<TerritoryScreen> createState() => _TerritoryScreenState();
}

class _TerritoryScreenState extends ConsumerState<TerritoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final territoryState = ref.watch(territoryProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final currentUserId = user?.id ?? 'u_shravan';

    final myTerritories = territoryState.territories
        .where((t) => t.isOwnedBy(currentUserId))
        .toList();
    final rivalTerritories = territoryState.territories
        .where((t) => !t.isOwnedBy(currentUserId))
        .toList();

    final totalArea = myTerritories.fold(0.0, (sum, t) => sum + t.areaKm2);

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        title: const Text(
          'TERRITORY COMMAND',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Territories',
            icon: territoryState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.neonCyan,
                    ),
                  )
                : const Icon(Icons.refresh, color: AppColors.neonCyan),
            onPressed: territoryState.isLoading
                ? null
                : () => ref.read(territoryProvider.notifier).loadTerritories(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonCyan,
          labelColor: AppColors.neonCyan,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text('SECTORS (${myTerritories.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_edu_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text('BATTLE LOG (${territoryState.events.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: SECTORS VIEW
          _buildSectorsTab(
            context,
            territoryState,
            myTerritories,
            rivalTerritories,
            totalArea,
          ),

          // TAB 2: BATTLE EVENT HISTORY LOG
          _buildEventLogTab(territoryState),
        ],
      ),
    );
  }

  // --- SECTORS TAB ---
  Widget _buildSectorsTab(
    BuildContext context,
    TerritoryState state,
    List<dynamic> myTerritories,
    List<dynamic> rivalTerritories,
    double totalArea,
  ) {
    // 1. Full Loading State (initial load)
    if (state.isLoading && state.territories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.neonCyan),
            const SizedBox(height: 16),
            const Text(
              'SCANNING SATELLITE SECTORS...',
              style: TextStyle(
                color: AppColors.neonCyan,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Full Error State with Retry
    if (state.hasError && state.territories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CyberCard(
            borderColor: AppColors.neonCrimson,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: AppColors.neonCrimson, size: 44),
                const SizedBox(height: 12),
                const Text(
                  'SATELLITE SYNC FAILED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'Unable to establish link with CONQUER territory server.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                CyberButton(
                  text: 'RETRY SATELLITE SYNC',
                  icon: Icons.refresh,
                  variant: CyberButtonVariant.crimson,
                  onPressed: () => ref.read(territoryProvider.notifier).loadTerritories(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.neonCyan,
      backgroundColor: AppColors.bgSurface,
      onRefresh: () => ref.read(territoryProvider.notifier).loadTerritories(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Temporary Error Banner if reload failed but cached data is present
          if (state.hasError) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.neonCrimson.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neonCrimson),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.neonCrimson, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live sync warning: ${state.errorMessage}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(territoryProvider.notifier).loadTerritories(),
                    child: const Text('RETRY', style: TextStyle(color: AppColors.neonCyan, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],

          // Empire Global Overview Banner
          CyberCard(
            borderColor: AppColors.neonBlue.withValues(alpha: 0.5),
            isGlowing: true,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SOVEREIGNTY OVERVIEW',
                      style: TextStyle(
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    CyberBadge(
                      label: '${myTerritories.length} SECTORS HELD',
                      color: AppColors.neonBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEmpireStat(
                      'TOTAL AREA',
                      '${totalArea.toStringAsFixed(2)} km²',
                      AppColors.neonCyan,
                    ),
                    _buildEmpireStat(
                      'DAILY YIELD',
                      '+${myTerritories.length * 35} Coins',
                      AppColors.neonGold,
                    ),
                    _buildEmpireStat(
                      'SECTOR STATUS',
                      myTerritories.any((t) => t.underAttack) ? 'ALERT' : 'SECURE',
                      myTerritories.any((t) => t.underAttack)
                          ? AppColors.neonCrimson
                          : AppColors.neonEmerald,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Under Attack / Incursion alerts
          for (final territory in myTerritories.where((t) => t.underAttack)) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.neonCrimson, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTESTED: ${territory.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Rival syndicate activity detected inside this sector.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CyberButton(
                    text: 'REINFORCE',
                    height: 38,
                    variant: CyberButtonVariant.crimson,
                    onPressed: () {
                      ref
                          .read(territoryProvider.notifier)
                          .reinforceTerritory(territory.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '🛡️ ${territory.name} reinforced! Defense +1.'),
                          backgroundColor: AppColors.bgSurface,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          // Section: Held Territories
          const Text(
            'HELD SECTORS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // Empty state when user holds 0 territories
          if (myTerritories.isEmpty) ...[
            CyberCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(Icons.shield_outlined, size: 40, color: AppColors.textDim),
                  const SizedBox(height: 10),
                  const Text(
                    'NO SECTORS CONQUERED YET',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Step outside and walk a closed loop over 100 meters to capture your first territory and claim XP rewards!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  CyberButton(
                    text: 'START PATROL NOW',
                    icon: Icons.navigation,
                    variant: CyberButtonVariant.cyan,
                    onPressed: () => context.go('/active-conquest'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          for (final t in myTerritories) ...[
            CyberCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CyberBadge(
                        label: t.underAttack ? 'UNDER SIEGE' : 'SECURE',
                        color: t.underAttack
                            ? AppColors.neonCrimson
                            : AppColors.neonEmerald,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildDetailPill(
                          Icons.straighten, '${t.areaKm2.toStringAsFixed(2)} km²'),
                      const SizedBox(width: 12),
                      _buildDetailPill(
                          Icons.security, 'Defense Level ${t.defenseLevel}'),
                      const SizedBox(width: 12),
                      _buildDetailPill(
                          Icons.monetization_on, '+35 / day'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Owner: ${t.ownerName}',
                        style: const TextStyle(color: AppColors.neonCyan, fontSize: 11),
                      ),
                      CyberButton(
                        text: 'REINFORCE (20 Coins)',
                        icon: Icons.shield,
                        height: 36,
                        variant: CyberButtonVariant.cyan,
                        onPressed: () {
                          ref
                              .read(territoryProvider.notifier)
                              .reinforceTerritory(t.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '🛡️ ${t.name} reinforced to Defense Level ${t.defenseLevel + 1}!'),
                              backgroundColor: AppColors.bgSurface,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),
          // Section: Hostile Redoubts
          const Text(
            'HOSTILE SECTORS IN THEATER',
            style: TextStyle(
              color: AppColors.neonCrimson,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          if (rivalTerritories.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No enemy territories detected in your immediate theater.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],

          for (final rival in rivalTerritories) ...[
            CyberCard(
              borderColor: AppColors.neonCrimson.withValues(alpha: 0.35),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rival.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Occupied by ${rival.ownerName} • ${rival.areaKm2.toStringAsFixed(2)} km²',
                          style: const TextStyle(
                            color: AppColors.neonCrimson,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CyberButton(
                    text: 'RAID SECTOR',
                    icon: Icons.flash_on,
                    height: 36,
                    variant: CyberButtonVariant.crimson,
                    onPressed: () {
                      context.go('/active-conquest');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '⚔️ Incursion mission locked: ${rival.name}. Walk a loop enclosing part of their land!'),
                          backgroundColor: AppColors.bgSurface,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // --- BATTLE LOG TAB ---
  Widget _buildEventLogTab(TerritoryState state) {
    if (state.isLoading && state.events.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonCyan),
      );
    }

    if (state.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_toggle_off, size: 48, color: AppColors.textDim),
              const SizedBox(height: 12),
              const Text(
                'NO BATTLE ENGAGEMENTS RECORDED',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'When you or rival commanders capture or slice territory, live battle updates will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.neonCyan,
      backgroundColor: AppColors.bgSurface,
      onRefresh: () => ref.read(territoryProvider.notifier).loadTerritories(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.events.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final event = state.events[index];
          final isCapture = event.type == 'capture' || event.stolenAreaKm2 > 0;

          return CyberCard(
            borderColor: isCapture
                ? AppColors.neonCrimson.withValues(alpha: 0.4)
                : AppColors.neonCyan.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isCapture ? AppColors.neonCrimson : AppColors.neonCyan)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCapture ? Icons.flash_on : Icons.verified,
                    color: isCapture ? AppColors.neonCrimson : AppColors.neonCyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CyberBadge(
                            label: isCapture ? 'SECTOR CAPTURE' : 'NEW CONQUEST',
                            color: isCapture ? AppColors.neonCrimson : AppColors.neonEmerald,
                          ),
                          Text(
                            _formatEventTime(event.timestamp),
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Actor: ${event.actorName}',
                            style: const TextStyle(
                              color: AppColors.neonCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (event.areaKm2 > 0) ...[
                            const SizedBox(width: 10),
                            Text(
                              'Area: ${event.areaKm2.toStringAsFixed(2)} km²',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpireStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildDetailPill(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.neonCyan),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  String _formatEventTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
