import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import '../data/services/backend_territory_service.dart';
import 'auth_provider.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.read).length;

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  late final BackendTerritoryService _service;

  @override
  NotificationState build() {
    _service = BackendTerritoryService();
    Future.microtask(() => loadNotifications());
    return const NotificationState();
  }

  Future<void> loadNotifications() async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? 'u_shravan';

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final notifs = await _service.fetchNotifications(userId);
      if (!ref.mounted) return;
      state = state.copyWith(
        notifications: notifs,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to sync notifications: $e',
      );
    }
  }

  Future<void> markAsRead(String id) async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? 'u_shravan';

    await _service.markNotificationAsRead(id, userId);

    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(read: true);
      return n;
    }).toList();

    state = state.copyWith(notifications: updated);
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
