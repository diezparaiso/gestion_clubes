import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/player.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) => PlayerRepository());

class PlayerRepository {
  Future<List<Player>> listTeamPlayers(String teamId) async {
    if (!SupabaseService.isConfigured) return _demoPlayers;
    final rows = await Supabase.instance.client
        .from('team_players')
        .select('id, jersey_number, is_active, players!inner(profiles!inner(first_name, last_name))')
        .eq('team_id', teamId)
        .order('jersey_number');
    return rows.map(Player.fromJson).toList();
  }

  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Alta/asignación de jugadores, coherencia club_id, validación de equipo y edición de dorsal/estado.
  // El alta reutiliza una cuenta existente de profiles y las tablas players/team_players.
  Future<Player> createAndAssignPlayer({
    required String clubId,
    required String teamId,
    required String firstName,
    required String lastName,
    required String email,
    required int? jerseyNumber,
  }) async {
    if (!SupabaseService.isConfigured) {
      final nextId = 'player-${_demoPlayers.length + 1}';
      final player = Player(
        id: nextId,
        name: '$firstName $lastName'.trim(),
        jerseyNumber: jerseyNumber,
        isActive: true,
      );
      _demoPlayers.add(player);
      return player;
    }

    final client = Supabase.instance.client;
    final team = await client
        .from('teams')
        .select('id')
        .eq('id', teamId)
        .eq('club_id', clubId)
        .maybeSingle();
    if (team == null) {
      throw const PostgrestException(message: 'El equipo no pertenece al club activo.');
    }

    final profile = await client
        .from('profiles')
        .select('id')
        .eq('email', email.trim())
        .maybeSingle();

    if (profile == null) {
      throw const PostgrestException(
        message: 'No existe una cuenta con ese email. El jugador debe registrarse antes de añadirlo.',
      );
    }

    final profileId = profile['id'] as String;
    final existingPlayer = await client
        .from('players')
        .select('id')
        .eq('club_id', clubId)
        .eq('profile_id', profileId)
        .maybeSingle();

    final playerId = existingPlayer?['id'] as String? ??
        (await client
                .from('players')
                .insert({'club_id': clubId, 'profile_id': profileId})
                .select('id')
                .single())['id'] as String;

    final row = await client
        .from('team_players')
        .insert({
          'club_id': clubId,
          'team_id': teamId,
          'player_id': playerId,
          'jersey_number': jerseyNumber,
          'is_active': true,
        })
        .select(
          'id, jersey_number, is_active, players!inner(profiles!inner(first_name, last_name))',
        )
        .single();

    return Player.fromJson(row);
  }

  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Verifica el equipo antes de editar una asignación.
  Future<Player> updateTeamPlayer({
    required String clubId,
    required String teamId,
    required String playerId,
    required int? jerseyNumber,
    required bool isActive,
  }) async {
    if (!SupabaseService.isConfigured) {
      final index = _demoPlayers.indexWhere((player) => player.id == playerId);
      if (index < 0) throw StateError('Jugador no encontrado.');
      final current = _demoPlayers[index];
      final updated = Player(
        id: current.id,
        name: current.name,
        jerseyNumber: jerseyNumber,
        isActive: isActive,
      );
      _demoPlayers[index] = updated;
      return updated;
    }
    final client = Supabase.instance.client;
    final team = await client
        .from('teams')
        .select('id')
        .eq('id', teamId)
        .eq('club_id', clubId)
        .maybeSingle();
    if (team == null) {
      throw const PostgrestException(message: 'El equipo no pertenece al club activo.');
    }
    final row = await client
        .from('team_players')
        .update({
          'jersey_number': jerseyNumber,
          'is_active': isActive,
        })
        .eq('id', playerId)
        .eq('team_id', teamId)
        .select(
          'id, jersey_number, is_active, players!inner(profiles!inner(first_name, last_name))',
        )
        .single();
    return Player.fromJson(row);
  }

  static final _demoPlayers = <Player>[
    Player(id: 'player-1', name: 'Álvaro Sánchez', jerseyNumber: 9, isActive: true),
    Player(id: 'player-2', name: 'Diego Romero', jerseyNumber: 4, isActive: true),
    Player(id: 'player-3', name: 'Nico Torres', jerseyNumber: 18, isActive: true),
  ];
}
