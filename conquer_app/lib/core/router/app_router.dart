import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/home_map/screens/home_map_screen.dart';
import '../../features/active_conquest/screens/active_conquest_screen.dart';
import '../../features/activity_history/screens/activity_history_screen.dart';
import '../../features/territory/screens/territory_screen.dart';
import '../../features/conquest_result/screens/conquest_result_screen.dart';
import '../../data/models/conquest_result_model.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../shared/widgets/scaffold_with_nav.dart';
import '../../providers/auth_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final seenOnboarding = authState.hasSeenOnboarding;

      final isGoingToOnboarding = state.matchedLocation == '/onboarding';
      final isGoingToAuth = state.matchedLocation == '/auth';

      if (!seenOnboarding && !isGoingToOnboarding) {
        return '/onboarding';
      }
      if (!isAuth && !isGoingToAuth && !isGoingToOnboarding) {
        return '/auth';
      }
      if (isAuth && (isGoingToAuth || isGoingToOnboarding)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/active-conquest',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ActiveConquestScreen(),
      ),
      GoRoute(
        path: '/conquest-result',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final result = state.extra as ConquestResultModel?;
          if (result == null) {
            return const HomeMapScreen();
          }
          return ConquestResultScreen(result: result);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeMapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const ActivityHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/territory',
                builder: (context, state) => const TerritoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
