import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/team_staff.dart';

final teamStaffRepositoryProvider = Provider<TeamStaffRepository>((ref) => TeamStaffRepository());

class TeamStaffRepository {
  Future<List<TeamStaff>> listTeamStaff(String teamId) async {
    if (!SupabaseService.isConfigured) return _demoStaff;
    final rows = await Supabase.instance.client.from('team_staff').select('id, role, is_active, profiles!inner(first_name, last_name)').eq('team_id', teamId).order('role');
    return rows.map(TeamStaff.fromJson).toList();
  }

  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Valida que el equipo pertenece al club antes de asignar personal.
  Future<TeamStaff> createAndAssignStaff({
    required String clubId,
    required String teamId,
    required String email,
    required String role,
    DateTime? startDate,
  }) async {
    if (!SupabaseService.isConfigured) {
      final staff = TeamStaff(id: 'staff-${_demoStaff.length + 1}', name: email.trim(), role: role.trim(), isActive: true);
      _demoStaff.add(staff);
      return staff;
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
    final profile = await client.from('profiles').select('id, first_name, last_name, email').eq('email', email.trim()).maybeSingle();
    if (profile == null) throw const PostgrestException(message: 'No existe una cuenta con ese email. La persona debe registrarse antes de asignarla.');
    final row = await client.from('team_staff').insert({
      'club_id': clubId,
      'team_id': teamId,
      'profile_id': profile['id'],
      'role': role.trim(),
      'start_date': (startDate ?? DateTime.now()).toIso8601String().split('T').first,
      'is_active': true,
    }).select('id, role, is_active, profiles!inner(first_name, last_name)').single();
    return TeamStaff.fromJson(row);
  }

  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Edición de rol/estado con columnas existentes.
  // No requiere cambios de esquema Supabase.
  Future<TeamStaff> updateTeamStaff({
    required String clubId,
    required String teamId,
    required String staffId,
    required String role,
    required bool isActive,
  }) async {
    if (!SupabaseService.isConfigured) {
      final index = _demoStaff.indexWhere((staff) => staff.id == staffId);
      if (index < 0) throw StateError('Personal no encontrado.');
      final current = _demoStaff[index];
      final updated = TeamStaff(id: current.id, name: current.name, role: role.trim(), isActive: isActive);
      _demoStaff[index] = updated;
      return updated;
    }
    final team = await Supabase.instance.client
        .from('teams')
        .select('id')
        .eq('id', teamId)
        .eq('club_id', clubId)
        .maybeSingle();
    if (team == null) {
      throw const PostgrestException(message: 'El equipo no pertenece al club activo.');
    }
    final row = await Supabase.instance.client.from('team_staff').update({
      'role': role.trim(),
      'is_active': isActive,
    }).eq('id', staffId).eq('team_id', teamId)
      .select('id, role, is_active, profiles!inner(first_name, last_name)')
      .single();
    return TeamStaff.fromJson(row);
  }

  static final _demoStaff = <TeamStaff>[
    TeamStaff(id: 'staff-1', name: 'Carlos Navarro', role: 'Entrenador principal', isActive: true),
    TeamStaff(id: 'staff-2', name: 'Elena Ruiz', role: 'Entrenadora asistente', isActive: true),
  ];
}
