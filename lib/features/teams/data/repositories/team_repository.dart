import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/season.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) => TeamRepository());

class TeamRepository {
  Future<List<Team>> listTeams(String clubId) async {
    if (!SupabaseService.isConfigured) return List.unmodifiable(_demoTeams);
    final rows = await Supabase.instance.client
        .from('teams')
        .select('id, name, category, is_active, seasons!inner(name)')
        .eq('club_id', clubId)
        .order('name');
    return rows.map(Team.fromJson).toList();
  }

  Future<List<Season>> listSeasons(String clubId) async {
    if (!SupabaseService.isConfigured) return _demoSeasons;
    final rows = await Supabase.instance.client.from('seasons').select('id, name').eq('club_id', clubId).order('start_date', ascending: false);
    return rows.map(Season.fromJson).toList();
  }

  Future<Team> createTeam({required String clubId, required String name, required String category, required String seasonId, required String seasonName}) async {
    if (!SupabaseService.isConfigured) {
      final team = Team(id: 'team-${_demoTeams.length + 1}', name: name, category: category, seasonName: seasonName, isActive: true);
      _demoTeams.add(team);
      return team;
    }
    final row = await Supabase.instance.client.from('teams').insert({
      'club_id': clubId,
      'name': name.trim(),
      'category': category.trim(),
      'season_id': seasonId,
    }).select('id, name, category, is_active, seasons!inner(name)').single();
    return Team.fromJson(row);
  }

  static final _demoTeams = <Team>[
    Team(id: 'team-a', name: 'Primer equipo', category: 'Senior masculina', seasonName: '2026/2027', isActive: true),
    Team(id: 'team-b', name: 'Juvenil A', category: 'Juvenil', seasonName: '2026/2027', isActive: true),
    Team(id: 'team-c', name: 'Alevín', category: 'Alevín', seasonName: '2026/2027', isActive: true),
  ];

  static const _demoSeasons = [
    Season(id: 'season-current', name: '2026/2027'),
    Season(id: 'season-previous', name: '2025/2026'),
  ];
}
