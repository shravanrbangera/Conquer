import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import 'cyber_badge.dart';
import 'cyber_card.dart';

class NotificationsModal extends ConsumerWidget {
  const NotificationsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const NotificationsModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);
    final notifNotifier = ref.read(notificationProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.neonCyan, width: 1.5),
          left: BorderSide(color: AppColors.borderSubtle),
          right: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AppColors.neonCyan, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'SECTOR TRANSMISSIONS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (notifState.unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      CyberBadge(
                        label: '${notifState.unreadCount} NEW',
                        color: AppColors.neonCrimson,
                      ),
                    ],
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.neonCyan, size: 20),
                  onPressed: () => notifNotifier.loadNotifications(),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderSubtle, height: 1),

          // Content
          Expanded(
            child: notifState.isLoading && notifState.notifications.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
                : notifState.notifications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.notifications_none, size: 48, color: AppColors.textDim),
                              const SizedBox(height: 12),
                              const Text(
                                'TRANSMISSION SILENCE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'No defense alarms, conquest confirmations, or hostile incursion alerts.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifState.notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final notif = notifState.notifications[index];
                          final isAttack = notif.type == 'attack_alert' || notif.type == 'capture';
                          final isAchievement = notif.type == 'achievement';

                          Color badgeColor = AppColors.neonCyan;
                          if (isAttack) badgeColor = AppColors.neonCrimson;
                          if (isAchievement) badgeColor = AppColors.neonGold;

                          return GestureDetector(
                            onTap: () {
                              if (!notif.read) {
                                notifNotifier.markAsRead(notif.id);
                              }
                            },
                            child: CyberCard(
                              borderColor: notif.read
                                  ? AppColors.borderSubtle
                                  : badgeColor.withValues(alpha: 0.6),
                              isGlowing: !notif.read,
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: badgeColor.withValues(alpha: 0.15),
                                    ),
                                    child: Icon(
                                      isAttack
                                          ? Icons.warning_amber_rounded
                                          : isAchievement
                                              ? Icons.military_tech
                                              : Icons.verified,
                                      color: badgeColor,
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
                                            Text(
                                              notif.title,
                                              style: TextStyle(
                                                color: notif.read ? AppColors.textMuted : Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              _formatTime(notif.createdAt),
                                              style: const TextStyle(
                                                color: AppColors.textDim,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif.message,
                                          style: TextStyle(
                                            color: notif.read ? AppColors.textDim : Colors.white70,
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!notif.read) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
