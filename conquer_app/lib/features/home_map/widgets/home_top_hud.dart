import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/notifications_modal.dart';

class HomeTopHud extends ConsumerWidget {
  final UserModel user;

  const HomeTopHud({super.key, required this.user});

  void _showAccountSwitcher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.bgDeep,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppColors.neonCyan, width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.swap_horiz, color: AppColors.neonCyan),
                  SizedBox(width: 8),
                  Text(
                    'SWITCH ACTIVE COMMANDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildAccountOption(
                context,
                ref,
                userId: 'u_shravan',
                username: 'SHRAVAN',
                role: 'Vanguard (Blue)',
                color: const Color(0xFF3B82F6),
                avatar: '⚔️',
                isSelected: user.id == 'u_shravan',
              ),
              const SizedBox(height: 10),
              _buildAccountOption(
                context,
                ref,
                userId: 'u_rahul',
                username: 'RAHUL',
                role: 'Shadow Syndicate (Red)',
                color: const Color(0xFFEF4444),
                avatar: '🛡️',
                isSelected: user.id == 'u_rahul',
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountOption(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required String username,
    required String role,
    required Color color,
    required String avatar,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          ref.read(authProvider.notifier).switchAccount(userId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched commander to $username ($role).'),
              backgroundColor: AppColors.bgSurface,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
                border: Border.all(color: color),
              ),
              child: Text(avatar, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    role,
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: user.playerColor.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar & Level Badge - tap to switch commander
          GestureDetector(
            onTap: () => _showAccountSwitcher(context, ref),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: user.playerColor.withValues(alpha: 0.2),
                    border: Border.all(color: user.playerColor, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(user.avatar, style: const TextStyle(fontSize: 17)),
                ),
                Positioned(
                  bottom: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: user.playerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'L${user.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // User Info & XP Bar - tap to switch account
          Expanded(
            child: GestureDetector(
              onTap: () => _showAccountSwitcher(context, ref),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 16),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: user.xpProgress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(user.playerColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Coins Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neonGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, size: 13, color: AppColors.neonGold),
                const SizedBox(width: 3),
                Text(
                  '${user.coins}',
                  style: const TextStyle(
                    color: AppColors.neonGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Notifications Bell with Unread Badge
          GestureDetector(
            onTap: () => NotificationsModal.show(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                shape: BoxShape.circle,
                border: Border.all(
                  color: notifState.unreadCount > 0
                      ? AppColors.neonCrimson
                      : AppColors.borderSubtle,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    notifState.unreadCount > 0
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    size: 18,
                    color: notifState.unreadCount > 0
                        ? AppColors.neonCrimson
                        : AppColors.neonCyan,
                  ),
                  if (notifState.unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.neonCrimson,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
