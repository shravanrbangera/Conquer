import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/services/backend_territory_service.dart';
import '../data/sources/mock_data.dart';
import 'territory_provider.dart';
import 'notification_provider.dart';

class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool hasSeenOnboarding;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isAuthenticated = true,
    this.hasSeenOnboarding = true,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? hasSeenOnboarding,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final BackendTerritoryService _service;

  @override
  AuthState build() {
    _service = BackendTerritoryService();

    // Sync live profile from backend on launch
    Future.microtask(() => syncUserProfile());

    return const AuthState(
      user: MockData.currentUser,
      isAuthenticated: true,
      hasSeenOnboarding: true,
    );
  }

  Future<void> syncUserProfile() async {
    final currentUserId = state.user?.id ?? 'u_shravan';
    try {
      final user = await _service.fetchUserProfile(currentUserId);
      if (!ref.mounted) return;
      state = state.copyWith(user: user);
    } catch (_) {
      // Keep existing user on connection error
    }
  }

  void completeOnboarding() {
    state = state.copyWith(hasSeenOnboarding: true);
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      user: MockData.currentUser,
    );
    return true;
  }

  /// Switches active user account between different players (e.g. u_shravan vs u_rahul)
  Future<void> switchAccount(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final switchedUser = await _service.switchUser(userId);
      if (!ref.mounted) return;
      state = state.copyWith(
        user: switchedUser,
        isLoading: false,
        isAuthenticated: true,
      );

      // Refresh territories and notifications for newly switched user
      ref.read(territoryProvider.notifier).loadTerritories();
      ref.read(notificationProvider.notifier).loadNotifications();
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to switch account: $e',
      );
    }
  }

  void updateUser(UserModel updatedUser) {
    state = state.copyWith(user: updatedUser);
  }

  void logout() {
    state = state.copyWith(
      isAuthenticated: false,
      user: null,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

