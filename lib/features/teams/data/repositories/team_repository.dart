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
    final rows = await Supabase.instance.client.from('seasons').select('id, name, start_date').eq('club_id', clubId).order('start_date', ascending: false);
    return rows.map(Season.fromJson).toList();
  }

  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26): CRUD de temporadas con columnas existentes.
  Future<Season> createSeason({required String clubId, required String name, required DateTime startDate}) async {
    if (!SupabaseService.isConfigured) {
      final season = Season(id: 'season-${_demoSeasons.length + 1}', name: name.trim(), startDate: startDate);
      _demoSeasons.add(season);
      return season;
    }
    final row = await Supabase.instance.client.from('seasons').insert({
      'club_id': clubId,
      'name': name.trim(),
      'start_date': startDate.toIso8601String().split('T').first,
    }).select('id, name, start_date').single();
    return Season.fromJson(row);
  }

  Future<Season> updateSeason({required String clubId, required String seasonId, required String name, required DateTime startDate}) async {
    if (!SupabaseService.isConfigured) {
      final index = _demoSeasons.indexWhere((season) => season.id == seasonId);
      if (index < 0) throw StateError('Temporada no encontrada.');
      final updated = Season(id: seasonId, name: name.trim(), startDate: startDate);
      _demoSeasons[index] = updated;
      return updated;
    }
    final row = await Supabase.instance.client.from('seasons').update({
      'name': name.trim(),
      'start_date': startDate.toIso8601String().split('T').first,
    }).eq('id', seasonId).eq('club_id', clubId).select('id, name, start_date').single();
    return Season.fromJson(row);
  }

  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Valida nombre, categoría y pertenencia de la temporada al club.
  Future<Team> createTeam({required String clubId, required String name, required String category, required String seasonId, required String seasonName}) async {
    final normalizedName = name.trim();
    final normalizedCategory = category.trim();
    if (normalizedName.isEmpty || normalizedCategory.isEmpty) {
      throw FormatException('El nombre y la categoría del equipo son obligatorios.');
    }
    if (!SupabaseService.isConfigured) {
      final team = Team(id: 'team-${_demoTeams.length + 1}', name: normalizedName, category: normalizedCategory, seasonName: seasonName, isActive: true);
      _demoTeams.add(team);
      return team;
    }
    final season = await Supabase.instance.client.from('seasons').select('id').eq('id', seasonId).eq('club_id', clubId).maybeSingle();
    if (season == null) throw const PostgrestException(message: 'La temporada no pertenece al club activo.');
    final row = await Supabase.instance.client.from('teams').insert({
      'club_id': clubId,
      'name': normalizedName,
      'category': normalizedCategory,
      'season_id': seasonId,
    }).select('id, name, category, is_active, seasons!inner(name)').single();
    return Team.fromJson(row);
  }

  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26):
  // Usa exclusivamente tablas y columnas que ya existen.
  // NO crea ni modifica migraciones, tablas, columnas ni políticas de Supabase.
  Future<Team> updateTeam({
    required String clubId,
    required String teamId,
    required String name,
    required String category,
    required String seasonId,
  }) async {
    if (!SupabaseService.isConfigured) {
      final index = _demoTeams.indexWhere((team) => team.id == teamId);
      if (index < 0) throw StateError('Equipo no encontrado.');
      final current = _demoTeams[index];
      final season = _demoSeasons.firstWhere((item) => item.id == seasonId, orElse: () => _demoSeasons.first);
      final updated = Team(id: current.id, name: name.trim(), category: category.trim(), seasonName: season.name, isActive: current.isActive);
      _demoTeams[index] = updated;
      return updated;
    }
    final season = await Supabase.instance.client.from('seasons').select('id').eq('id', seasonId).eq('club_id', clubId).maybeSingle();
    if (season == null) throw const PostgrestException(message: 'La temporada no pertenece al club activo.');
    final row = await Supabase.instance.client.from('teams').update({
      'name': name.trim(),
      'category': category.trim(),
      'season_id': seasonId,
    }).eq('id', teamId).eq('club_id', clubId).select('id, name, category, is_active, seasons!inner(name)').single();
    return Team.fromJson(row);
  }

  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26):
  // Baja lógica mediante is_active; no elimina físicamente el equipo.
  Future<Team> setTeamActive({required String clubId, required String teamId, required bool isActive}) async {
    if (!SupabaseService.isConfigured) {
      final index = _demoTeams.indexWhere((team) => team.id == teamId);
      if (index < 0) throw StateError('Equipo no encontrado.');
      final current = _demoTeams[index];
      final updated = Team(id: current.id, name: current.name, category: current.category, seasonName: current.seasonName, isActive: isActive);
      _demoTeams[index] = updated;
      return updated;
    }
    final row = await Supabase.instance.client.from('teams').update({'is_active': isActive}).eq('id', teamId).eq('club_id', clubId).select('id, name, category, is_active, seasons!inner(name)').single();
    return Team.fromJson(row);
  }
  static final _demoTeams = <Team>[
    Team(id: 'team-a', name: 'Primer equipo', category: 'Senior masculina', seasonName: '2026/2027', isActive: true),
    Team(id: 'team-b', name: 'Juvenil A', category: 'Juvenil', seasonName: '2026/2027', isActive: true),
    Team(id: 'team-c', name: 'Alevín', category: 'Alevín', seasonName: '2026/2027', isActive: true),
  ];

  static final _demoSeasons = <Season>[
    Season(id: 'season-current', name: '2026/2027', startDate: DateTime(2026, 7, 1)),
    Season(id: 'season-previous', name: '2025/2026', startDate: DateTime(2025, 7, 1)),
  ];
}
