import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/player.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) => PlayerRepository());

class PlayerRepository {
  Future<List<Player>> listTeamPlayers(String teamId) async {
    if (!SupabaseService.isConfigured) return _demoPlayers;
    final rows = await Supabase.instance.client.from('team_players').select('id, jersey_number, is_active, players!inner(profiles!inner(first_name, last_name))').eq('team_id', teamId).order('jersey_number');
    return rows.map(Player.fromJson).toList();
  }

  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Edición de dorsal/estado usando columnas existentes.
  // No requiere cambios de esquema Supabase.
  Future<Player> updateTeamPlayer({
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
    final row = await Supabase.instance.client.from('team_players').update({
      'jersey_number': jerseyNumber,
      'is_active': isActive,
    }).eq('id', playerId).eq('team_id', teamId)
      .select('id, jersey_number, is_active, players!inner(profiles!inner(first_name, last_name))')
      .single();
    return Player.fromJson(row);
  }

  static final _demoPlayers = <Player>[
    Player(id: 'player-1', name: 'Álvaro Sánchez', jerseyNumber: 9, isActive: true),
    Player(id: 'player-2', name: 'Diego Romero', jerseyNumber: 4, isActive: true),
    Player(id: 'player-3', name: 'Nico Torres', jerseyNumber: 18, isActive: true),
  ];
}
