import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';

/// Barra común de navegación de la gestión del club.
/// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): navegación centralizada por rol.
class ClubNavigationAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ClubNavigationAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final role = auth.role ?? '';
    final items = <({String label, String path, IconData icon})>[
      (label: 'Inicio', path: '/dashboard', icon: Icons.dashboard_outlined),
      if (_has(role, 'members')) (label: 'Socios', path: '/members', icon: Icons.people_outline),
      if (_has(role, 'teams')) (label: 'Equipos', path: '/teams', icon: Icons.groups_outlined),
      if (_has(role, 'finance')) (label: 'Tesorería', path: '/finance', icon: Icons.account_balance_wallet_outlined),
      if (_has(role, 'raffles')) (label: 'Rifas', path: '/raffles', icon: Icons.confirmation_number_outlined),
      if (_has(role, 'news')) (label: 'Noticias', path: '/news', icon: Icons.article_outlined),
      if (_has(role, 'events')) (label: 'Eventos', path: '/events', icon: Icons.event_outlined),
      (label: 'Notificaciones', path: '/notifications', icon: Icons.notifications_outlined),
      if (role == 'club_president' || role == 'club_secretary') (label: 'Configuración', path: '/settings', icon: Icons.settings_outlined),
      (label: 'Mi perfil', path: '/profile', icon: Icons.person_outline),
    ];
    return AppBar(
      leading: IconButton(
        tooltip: 'Volver al inicio',
        onPressed: () => context.go('/dashboard'),
        icon: const Icon(Icons.home_outlined),
      ),
      title: Text(title),
      actions: [
        ...?actions,
        if (items.length > 1)
          PopupMenuButton<String>(
            tooltip: 'Navegación',
            icon: const Icon(Icons.menu_open),
            onSelected: (path) => context.go(path),
            itemBuilder: (_) => items.map((item) => PopupMenuItem<String>(
              value: item.path,
              child: Row(children: [Icon(item.icon, size: 20), const SizedBox(width: 10), Text(item.label)]),
            )).toList(),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: Chip(avatar: const Icon(Icons.person_outline, size: 18), label: Text(auth.roleLabel)),
        ),
      ],
    );
  }

  static bool _has(String role, String section) {
    switch (section) {
      case 'members': return const ['club_president','club_secretary','member'].contains(role);
      case 'teams': return const ['club_president','club_secretary','team_manager','coach'].contains(role);
      case 'finance': return const ['club_president','club_treasurer'].contains(role);
      case 'raffles': return role == 'club_president';
      case 'news': return const ['club_president','club_secretary'].contains(role);
      case 'events': return const ['club_president','club_secretary'].contains(role);
      default: return true;
    }
  }
}
