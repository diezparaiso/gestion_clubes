import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/club_export_service.dart';

import '../../../auth/application/auth_controller.dart';
import '../../../clubs/data/repositories/club_repository.dart';
import '../../../clubs/domain/entities/club.dart';
import '../../application/dashboard_stats_provider.dart';

// MODIFICADO POR GPT-5.6 LUNA
// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Elimina actividad ficticia del dashboard.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Añade exportación completa de gestión a Excel.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Muestra el rol real del acceso seleccionado.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): Filtra navegación y acciones según permisos del rol.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): el Excel solo solicita módulos con permiso de lectura.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): incorpora Patrocinadores en navegación desktop/mobile.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): añade acceso directo a la web pública y mejora la identificación del usuario.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;
  late final Future<Club?> _publicClubFuture;

  @override
  void initState() {
    super.initState();
    final clubId = ref.read(authControllerProvider).clubId;
    _publicClubFuture = clubId == null || clubId.isEmpty
        ? Future.value(null)
        : ref.read(clubRepositoryProvider).getClubById(clubId);
  }

  static const _navigationItems = [
    (Icons.grid_view_rounded, 'Resumen'),
    (Icons.people_alt_outlined, 'Socios'),
    (Icons.groups_outlined, 'Equipos'),
    (Icons.account_balance_wallet_outlined, 'Tesorería'),
    (Icons.confirmation_number_outlined, 'Rifas'),
    (Icons.article_outlined, 'Noticias'),
    (Icons.event_outlined, 'Eventos'),
    (Icons.business_outlined, 'Patrocinadores'),
    (Icons.settings_outlined, 'Configuración'),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final stats = ref.watch(dashboardStatsProvider).valueOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (isDesktop) _buildSidebar(context, authState),
                Expanded(child: _buildContent(context, isDesktop, authState, stats)),
              ],
            ),
          ),
          bottomNavigationBar: isDesktop ? null : _buildBottomNavigation(),
        );
      },
    );
  }

  bool _can(AuthState authState, String permission) => ClubRolePermissions.has(authState.role, permission);

  String _navigationPermission(int index) => switch (index) {
    0 => 'dashboard_view', 1 => 'members_view', 2 => 'teams_view', 3 => 'finance_view',
    4 => 'raffles_view', 5 => 'news_view', 6 => 'events_view', 7 => 'sponsors_manage', 8 => 'club_settings_view',
    _ => 'dashboard_view',
  };

  Widget _buildSidebar(BuildContext context, AuthState authState) {
    return Container(
      width: 248,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      color: const Color(0xFF14213D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _BrandMark(),
              SizedBox(width: 10),
              Text(
                'CLUB PLATFORM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          const Text(
            'GESTIÓN DEL CLUB',
            style: TextStyle(
              color: Color(0xFF9BA9BC),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_navigationItems.length, (index) {
            final item = _navigationItems[index];
            if (!_can(authState, _navigationPermission(index))) return const SizedBox.shrink();
            return _NavigationTile(
              icon: item.$1,
              label: item.$2,
              selected: _selectedIndex == index,
              onTap: () {
                setState(() => _selectedIndex = index);
                if (index == 1) context.go('/members');
                if (index == 2) context.go('/teams');
                if (index == 3) context.go('/finance');
                if (index == 4) context.go('/raffles');
                if (index == 5) context.go('/news');
                if (index == 6) context.go('/events');
                if (index == 7) context.go('/sponsors');
                if (index == 8) context.go('/settings');
              },
            );
          }),
          const Spacer(),
          const Divider(color: Color(0x334B5D76)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _UserAvatar(initials: _userInitials(authState.email)),
            title: Text(authState.email ?? 'Usuario', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
            subtitle: Text(authState.roleLabel, style: const TextStyle(color: Color(0xFF9BA9BC))),
            trailing: IconButton(onPressed: () => ref.read(authControllerProvider.notifier).signOut(), tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout_rounded, color: Color(0xFF9BA9BC))),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDesktop, AuthState authState, DashboardStats? stats) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: isDesktop ? 34 : 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isDesktop ? 620 : double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authState.clubName ?? 'Tu club', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Hola, ${_displayName(authState.email)}', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      const Text('Aquí tienes el estado de tu club hoy.'),
                    ],
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openPublicClub(context),
                      icon: const Icon(Icons.public_rounded, size: 18),
                      label: const Text('Ver web pública'),
                    ),
                    IconButton(
                      onPressed: () => _exportClub(context),
                      tooltip: 'Exportar gestión a Excel',
                      icon: const Icon(Icons.file_download_outlined),
                    ),
                    if (_can(authState, 'notifications_view'))
                      IconButton(
                        onPressed: () => context.go('/notifications'),
                        tooltip: 'Notificaciones',
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    _UserAvatar(initials: _userInitials(authState.email), radius: 20),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildMetricGrid(isDesktop, stats),
            const SizedBox(height: 32),
            Text('Acciones rápidas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _buildQuickActions(isDesktop),
            const SizedBox(height: 32),
            _buildActivitySection(context, isDesktop, stats),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(bool isDesktop, DashboardStats? stats) {
    final metrics = [
      (Icons.account_balance_wallet_outlined, 'Saldo actual', _formatCurrency(stats?.balance ?? 0), 'Disponible', const Color(0xFF168B68)),
      (Icons.people_alt_outlined, 'Socios activos', '${stats?.memberCount ?? 0}', 'Directorio del club', const Color(0xFF3276B1)),
      (Icons.groups_outlined, 'Equipos', '${stats?.teamCount ?? 0}', 'Equipos del club', const Color(0xFFD27A2C)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 2.25 : 3.2,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: metric.$5.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(metric.$1, color: metric.$5),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(metric.$2, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(metric.$3, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF14213D))),
                    Text(metric.$4, style: TextStyle(fontSize: 12, color: metric.$5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(bool isDesktop) {
    final authState = ref.read(authControllerProvider);
    final actions = [
      (Icons.person_add_alt_1_outlined, 'Nuevo socio', const Color(0xFF168B68), '/members', 'members_manage'),
      (Icons.add_chart_outlined, 'Registrar ingreso', const Color(0xFF3276B1), '/finance', 'finance_manage'),
      (Icons.receipt_long_outlined, 'Registrar gasto', const Color(0xFFD27A2C), '/finance', 'finance_manage'),
      (Icons.local_activity_outlined, 'Crear rifa', const Color(0xFF8B5E9E), '/raffles', 'raffles_manage'),
    ];
    final visibleActions = actions.where((action) => _can(authState, action.$5)).toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: visibleActions.map((action) {
        return SizedBox(
          width: isDesktop ? 190 : double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(action.$4),
            icon: Icon(action.$1, size: 20, color: action.$3),
            label: Text(action.$2),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              side: const BorderSide(color: Color(0xFFD9E0DD)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivitySection(BuildContext context, bool isDesktop, DashboardStats? stats) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        SizedBox(
          width: isDesktop ? 560 : double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estado operativo', style: Theme.of(context).textTheme.titleLarge),
                      if (_can(ref.read(authControllerProvider), 'members_view'))
                        TextButton(onPressed: () => context.go('/members'), child: const Text('Ver socios')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ActivityItem(icon: Icons.people_alt_outlined, title: '${stats?.memberCount ?? 0} socios registrados', detail: 'Directorio actual del club', color: const Color(0xFF168B68)),
                  _ActivityItem(icon: Icons.groups_outlined, title: '${stats?.teamCount ?? 0} equipos registrados', detail: 'Equipos actuales del club', color: const Color(0xFF3276B1)),
                  _ActivityItem(icon: Icons.account_balance_wallet_outlined, title: 'Saldo ${_formatCurrency(stats?.balance ?? 0)}', detail: 'Saldo calculado con los movimientos registrados', color: const Color(0xFFD27A2C)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: isDesktop ? 300 : double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen del mes', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  _SummaryLine(label: 'Ingresos', value: _formatCurrency(stats?.income ?? 0), color: const Color(0xFF168B68)),
                  const SizedBox(height: 16),
                  _SummaryLine(label: 'Gastos', value: _formatCurrency(stats?.expenses ?? 0), color: const Color(0xFFD27A2C)),
                  const Divider(height: 32),
                  _SummaryLine(label: 'Balance', value: _formatCurrency(stats?.balance ?? 0), color: const Color(0xFF14213D), bold: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportClub(BuildContext context) async {
    final auth = ref.read(authControllerProvider);
    final clubId = auth.clubId;
    if (clubId == null || clubId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay un club activo para exportar.')),
      );
      return;
    }
    try {
      await ClubExportService().exportClub(
        clubId: clubId,
        clubName: auth.clubName ?? 'club',
        permissions: {
          for (final permission in const ['finance_view', 'members_view', 'teams_view', 'players_view', 'news_view', 'events_view', 'raffles_view'])
            if (ClubRolePermissions.has(auth.role, permission)) permission,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Excel de gestión generado. Revisa la descarga del navegador.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('No se ha podido exportar la gestión: $error')),
      );
    }
  }

  Future<void> _openPublicClub(BuildContext context) async {
    try {
      final club = await _publicClubFuture;
      if (!mounted) return;
      if (club == null || club.slug.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se ha podido localizar la página pública del club.')),
        );
        return;
      }
      context.go('/club/${Uri.encodeComponent(club.slug)}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido abrir la página pública del club.')),
      );
    }
  }

  String _displayName(String? email) {
    final localPart = email?.split('@').first.trim();
    if (localPart == null || localPart.isEmpty) return 'de nuevo';
    final words = localPart.replaceAll(RegExp(r'[._-]+'), ' ').trim().split(RegExp(r'\s+'));
    return words.map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String _userInitials(String? email) {
    final name = _displayName(email);
    if (name == 'de nuevo') return 'U';
    final words = name.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
  }

  String _formatCurrency(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

  Widget _buildBottomNavigation() {
    final authState = ref.read(authControllerProvider);
    final visibleEntries = List.generate(_navigationItems.length, (index) => (index, _navigationItems[index]))
        .where((entry) => _can(authState, _navigationPermission(entry.$1)))
        .toList();
    final selectedVisibleIndex = visibleEntries.indexWhere((entry) => entry.$1 == _selectedIndex);
    return NavigationBar(
      selectedIndex: selectedVisibleIndex < 0 ? 0 : selectedVisibleIndex,
      onDestinationSelected: (visibleIndex) {
        final index = visibleEntries[visibleIndex].$1;
        setState(() => _selectedIndex = index);
        if (index == 1) context.go('/members');
        if (index == 2) context.go('/teams');
        if (index == 3) context.go('/finance');
        if (index == 4) context.go('/raffles');
        if (index == 5) context.go('/news');
        if (index == 6) context.go('/events');
        if (index == 7) context.go('/sponsors');
        if (index == 8) context.go('/settings');
      },
      destinations: visibleEntries
          .map((entry) => NavigationDestination(icon: Icon(entry.$2.$1), label: entry.$2.$2))
          .toList(),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.initials, this.radius = 20});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE4B363),
      child: Text(
        initials,
        style: TextStyle(
          color: const Color(0xFF14213D),
          fontWeight: FontWeight.w800,
          fontSize: radius <= 20 ? 12 : 14,
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: const Color(0xFFE4B363), borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF14213D), size: 21),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selectedTileColor: const Color(0xFF236A59),
        leading: Icon(icon, color: selected ? Colors.white : const Color(0xFF9BA9BC)),
        title: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFFCBD4DE), fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.icon, required this.title, required this.detail, required this.color});

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 19)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF14213D))),
      subtitle: Text(detail),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value, required this.color, this.bold = false});

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: bold ? 18 : 15)),
      ],
    );
  }
}
