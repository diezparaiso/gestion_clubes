import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/team_staff_repository.dart';
import '../../domain/entities/team_staff.dart';

final teamStaffProvider = FutureProvider.family<List<TeamStaff>, String>((ref, teamId) {
  ref.watch(authControllerProvider);
  return ref.watch(teamStaffRepositoryProvider).listTeamStaff(teamId);
});

class TeamStaffPage extends ConsumerWidget {
  const TeamStaffPage({required this.teamId, required this.teamName, super.key});

  final String teamId;
  final String teamName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(teamStaffProvider(teamId));
    return Scaffold(
      appBar: AppBar(title: Text('$teamName · Personal')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cuerpo técnico', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Entrenadores y personal asignado a este equipo.'),
          const SizedBox(height: 24),
          Expanded(child: staff.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Center(child: Text('No se ha podido cargar el personal.')),
            data: (items) => Card(child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = items[index];
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE8EFEC), child: Icon(Icons.sports_outlined, color: Color(0xFF168B68))),
                  title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(member.role),
                  trailing: member.isActive ? const Icon(Icons.check_circle_outline, color: Color(0xFF168B68)) : const Icon(Icons.cancel_outlined, color: Color(0xFF9BA9BC)),
                );
              },
            )),
          )),
        ]),
      ),
    );
  }
}
