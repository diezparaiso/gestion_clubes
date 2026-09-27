import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): navegación basada en permisos en lugar de roles.

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
    final role = auth.role;
    bool can(String permission) => ClubRolePermissions.has(role, permission);
    final items = <({String label, String path, IconData icon})>[
      if (can('dashboard_view')) (label: 'Inicio', path: '/dashboard', icon: Icons.dashboard_outlined),
      if (can('members_view')) (label: 'Socios', path: '/members', icon: Icons.people_outline),
      if (can('teams_view')) (label: 'Equipos', path: '/teams', icon: Icons.groups_outlined),
      if (can('finance_view')) (label: 'Tesorería', path: '/finance', icon: Icons.account_balance_wallet_outlined),
      if (can('raffles_view')) (label: 'Rifas', path: '/raffles', icon: Icons.confirmation_number_outlined),
      if (can('news_view')) (label: 'Noticias', path: '/news', icon: Icons.article_outlined),
      if (can('events_view')) (label: 'Eventos', path: '/events', icon: Icons.event_outlined),
      if (can('notifications_view')) (label: 'Notificaciones', path: '/notifications', icon: Icons.notifications_outlined),
      if (can('club_settings_view')) (label: 'Configuración', path: '/settings', icon: Icons.settings_outlined),
      if (can('access_manage')) (label: 'Usuarios y permisos', path: '/settings/access', icon: Icons.manage_accounts_outlined),
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

}