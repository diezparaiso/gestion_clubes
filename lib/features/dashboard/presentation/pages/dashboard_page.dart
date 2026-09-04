import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_controller.dart';
import '../../application/dashboard_stats_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;

  static const _navigationItems = [
    (Icons.grid_view_rounded, 'Resumen'),
    (Icons.people_alt_outlined, 'Socios'),
    (Icons.groups_outlined, 'Equipos'),
    (Icons.account_balance_wallet_outlined, 'Tesorería'),
    (Icons.confirmation_number_outlined, 'Rifas'),
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
              },
            );
          }),
          const Spacer(),
          const Divider(color: Color(0x334B5D76)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE4B363),
              child: Text('PM', style: TextStyle(color: Color(0xFF14213D), fontWeight: FontWeight.w800)),
            ),
            title: Text(authState.email ?? 'Usuario', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
            subtitle: const Text('Presidente', style: TextStyle(color: Color(0xFF9BA9BC))),
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authState.clubName ?? 'Tu club', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Hola, ${authState.email?.split('@').first ?? 'de nuevo'}', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      const Text('Aquí tienes el estado de tu club hoy.'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  tooltip: 'Notificaciones',
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                const SizedBox(width: 4),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFE4B363),
                  child: Text('PM', style: TextStyle(color: Color(0xFF14213D), fontWeight: FontWeight.w800, fontSize: 12)),
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
      (Icons.confirmation_number_outlined, 'Rifas activas', '2', '34 participaciones nuevas', const Color(0xFFD27A2C)),
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
    final actions = [
      (Icons.person_add_alt_1_outlined, 'Nuevo socio', const Color(0xFF168B68)),
      (Icons.add_chart_outlined, 'Registrar ingreso', const Color(0xFF3276B1)),
      (Icons.receipt_long_outlined, 'Registrar gasto', const Color(0xFFD27A2C)),
      (Icons.local_activity_outlined, 'Crear rifa', const Color(0xFF8B5E9E)),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((action) {
        return SizedBox(
          width: isDesktop ? 190 : double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
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
                      Text('Actividad reciente', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(onPressed: () {}, child: const Text('Ver todo')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _ActivityItem(icon: Icons.person_add_alt_1, title: 'Nuevo socio #248', detail: 'Hace 24 minutos', color: Color(0xFF168B68)),
                  const _ActivityItem(icon: Icons.confirmation_number_outlined, title: 'Rifa Navidad', detail: '34 nuevas participaciones', color: Color(0xFFD27A2C)),
                  const _ActivityItem(icon: Icons.receipt_long_outlined, title: 'Material deportivo', detail: 'Gasto registrado · 350 €', color: Color(0xFF3276B1)),
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

  String _formatCurrency(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        if (index == 1) context.go('/members');
        if (index == 2) context.go('/teams');
        if (index == 3) context.go('/finance');
        if (index == 4) context.go('/raffles');
      },
      destinations: _navigationItems
          .map((item) => NavigationDestination(icon: Icon(item.$1), label: item.$2))
          .toList(),
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
