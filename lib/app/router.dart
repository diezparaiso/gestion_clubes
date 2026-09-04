import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/clubs/presentation/pages/club_onboarding_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/finance/presentation/pages/finance_page.dart';
import '../features/members/presentation/pages/members_page.dart';
import '../features/players/presentation/pages/team_players_page.dart';
import '../features/raffles/presentation/pages/raffles_page.dart';
import '../features/raffles/presentation/pages/public_raffle_page.dart';
import '../features/raffles/presentation/pages/raffle_detail_page.dart';
import '../features/raffles/domain/entities/raffle.dart';
import '../features/staff/presentation/pages/team_staff_page.dart';
import '../features/teams/presentation/pages/teams_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute = location == '/login' || location == '/register';
      final isPublicRaffle = location.startsWith('/r/');
      final isSignedIn = authState.status == AuthStatus.signedIn;
      final needsClub = authState.status == AuthStatus.needsClub;

      if (needsClub && location != '/onboarding') return '/onboarding';
      if (isSignedIn && isAuthRoute) return '/dashboard';
      if (!isSignedIn && !needsClub && !isAuthRoute && !isPublicRaffle) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/onboarding', name: 'onboarding', builder: (context, state) => const ClubOnboardingPage()),
      GoRoute(
        path: '/r/:clubSlug/:raffleSlug',
        name: 'public-raffle',
        builder: (context, state) => PublicRafflePage(
          clubSlug: state.pathParameters['clubSlug']!,
          raffleSlug: state.pathParameters['raffleSlug']!,
        ),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/finance',
        name: 'finance',
        builder: (context, state) => const FinancePage(),
      ),
      GoRoute(
        path: '/raffles',
        name: 'raffles',
        builder: (context, state) => const RafflesPage(),
      ),
      GoRoute(
        path: '/raffles/:raffleId',
        name: 'raffle-detail',
        builder: (context, state) {
          final raffle = state.extra as Raffle?;
          return RaffleDetailPage(
            raffle: raffle,
            raffleId: state.pathParameters['raffleId']!,
            clubId: ref.read(authControllerProvider).clubId,
          );
        },
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
      GoRoute(
        path: '/teams/:teamId/staff',
        name: 'team-staff',
        builder: (context, state) => TeamStaffPage(
          teamId: state.pathParameters['teamId']!,
          teamName: state.extra as String? ?? 'Equipo',
        ),
      ),
    ],
  );
});
