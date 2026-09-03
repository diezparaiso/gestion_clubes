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

  static const _demoPlayers = [
    Player(id: 'player-1', name: 'Álvaro Sánchez', jerseyNumber: 9, isActive: true),
    Player(id: 'player-2', name: 'Diego Romero', jerseyNumber: 4, isActive: true),
    Player(id: 'player-3', name: 'Nico Torres', jerseyNumber: 18, isActive: true),
  ];
}
