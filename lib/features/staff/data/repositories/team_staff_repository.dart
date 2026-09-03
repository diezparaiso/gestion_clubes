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

  static const _demoStaff = [
    TeamStaff(id: 'staff-1', name: 'Carlos Navarro', role: 'Entrenador principal', isActive: true),
    TeamStaff(id: 'staff-2', name: 'Elena Ruiz', role: 'Entrenadora asistente', isActive: true),
  ];
}
