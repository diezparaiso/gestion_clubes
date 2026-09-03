import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/clubs/presentation/pages/club_onboarding_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/members/presentation/pages/members_page.dart';
import '../features/players/presentation/pages/team_players_page.dart';
import '../features/teams/presentation/pages/teams_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute = location == '/login' || location == '/register';
      final isSignedIn = authState.status == AuthStatus.signedIn;
      final needsClub = authState.status == AuthStatus.needsClub;

      if (needsClub && location != '/onboarding') return '/onboarding';
      if (isSignedIn && isAuthRoute) return '/dashboard';
      if (!isSignedIn && !needsClub && !isAuthRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/onboarding', name: 'onboarding', builder: (context, state) => const ClubOnboardingPage()),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/members',
        name: 'members',
        builder: (context, state) => const MembersPage(),
      ),
      GoRoute(
        path: '/teams',
        name: 'teams',
        builder: (context, state) => const TeamsPage(),
      ),
      GoRoute(
        path: '/teams/:teamId/players',
        name: 'team-players',
        builder: (context, state) => TeamPlayersPage(
          teamId: state.pathParameters['teamId']!,
          teamName: state.extra as String? ?? 'Plantilla',
        ),
      ),
    ],
  );
});
