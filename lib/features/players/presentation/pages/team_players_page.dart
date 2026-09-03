import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/player_repository.dart';
import '../../domain/entities/player.dart';

final teamPlayersProvider = FutureProvider.family<List<Player>, String>((ref, teamId) {
  ref.watch(authControllerProvider);
  return ref.watch(playerRepositoryProvider).listTeamPlayers(teamId);
});

class TeamPlayersPage extends ConsumerWidget {
  const TeamPlayersPage({required this.teamId, required this.teamName, super.key});

  final String teamId;
  final String teamName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(teamPlayersProvider(teamId));
    return Scaffold(
      appBar: AppBar(title: Text(teamName)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Plantilla', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Jugadores asignados a este equipo.'),
          const SizedBox(height: 24),
          Expanded(child: players.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Center(child: Text('No se ha podido cargar la plantilla.')),
            data: (items) => Card(child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _PlayerTile(player: items[index]),
            )),
          )),
        ]),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: const Color(0xFFE4B363), child: Text(player.jerseyNumber?.toString() ?? '-')),
      title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(player.isActive ? 'Jugador activo' : 'Baja de equipo'),
    );
  }
}
