// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Refuerza validación de club, email y roles y evita cliente Supabase en modo demo.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/club_member.dart';

class ClubMemberRepository {
  final SupabaseClient? _supabase;

  ClubMemberRepository(this._supabase);

  /// Obtiene todos los miembros del club (para managers)
  Future<List<ClubMember>> getClubMembers(String clubId) async {
    if (!SupabaseService.isConfigured) {
      return _demoMembers();
    }
    final supabase = _supabase;
    if (supabase == null) return _demoMembers();

    try {
      final response = await supabase
          .from('club_memberships')
          .select('''
            id, club_id, profile_id, role, is_active, created_at, updated_at,
            profiles:profile_id (first_name, last_name, email)
          ''')
          .eq('club_id', clubId)
          .order('created_at', ascending: false);

      return (response as List).map((e) {
        final profile = e['profiles'] as Map<String, dynamic>?;
        return ClubMember.fromJson({
          ...e as Map<String, dynamic>,
          'first_name': profile?['first_name'],
          'last_name': profile?['last_name'],
          'email': profile?['email'],
        });
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener miembros: ${e.message}');
    }
  }

  /// Obtiene solo los miembros activos
  Future<List<ClubMember>> getActiveClubMembers(String clubId) async {
    if (!SupabaseService.isConfigured) {
      return _demoMembers().where((m) => m.isActive).toList();
    }

    try {
      final response = await _supabase
          .from('club_memberships')
          .select('''
            id, club_id, profile_id, role, is_active, created_at, updated_at,
            profiles:profile_id (first_name, last_name, email)
          ''')
          .eq('club_id', clubId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List).map((e) {
        final profile = e['profiles'] as Map<String, dynamic>?;
        return ClubMember.fromJson({
          ...e as Map<String, dynamic>,
          'first_name': profile?['first_name'],
          'last_name': profile?['last_name'],
          'email': profile?['email'],
        });
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener miembros activos: ${e.message}');
    }
  }

  /// Invita un usuario al club
  Future<bool> inviteClubMember(
    String clubId,
    String email,
    String role,
  ) async {
    _validateClubId(clubId);
    final normalizedEmail = _normalizeEmail(email);
    _validateRole(role);
    if (!SupabaseService.isConfigured) return true;
    final supabase = _supabase;
    if (supabase == null) return true;

    try {
      final result = await supabase.rpc(
        'invite_club_member',
        params: {
          'p_club_id': clubId,
          'p_email': normalizedEmail,
          'p_role': role,
        },
      );

      final success = result[0]['success'] as bool;
      if (!success) {
        throw Exception(result[0]['message'] as String);
      }
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Error al invitar miembro: ${e.message}');
    }
  }

  /// Cambia el rol de un miembro
  Future<bool> changeClubMemberRole(
    String clubId,
    String profileId,
    String newRole,
  ) async {
    _validateClubId(clubId);
    if (profileId.trim().isEmpty) throw ArgumentError('El perfil del miembro es obligatorio.');
    _validateRole(newRole);
    if (!SupabaseService.isConfigured) return true;
    final supabase = _supabase;
    if (supabase == null) return true;

    try {
      final result = await supabase.rpc(
        'change_member_role',
        params: {
          'p_club_id': clubId,
          'p_profile_id': profileId,
          'p_new_role': newRole,
        },
      );

      final success = result[0]['success'] as bool;
      if (!success) {
        throw Exception(result[0]['message'] as String);
      }
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Error al cambiar rol: ${e.message}');
    }
  }

  /// Revoca acceso de un miembro
  Future<bool> revokeClubMemberAccess(
    String clubId,
    String profileId,
  ) async {
    _validateClubId(clubId);
    if (profileId.trim().isEmpty) throw ArgumentError('El perfil del miembro es obligatorio.');
    if (!SupabaseService.isConfigured) return true;
    final supabase = _supabase;
    if (supabase == null) return true;

    try {
      final result = await supabase.rpc(
        'revoke_member_access',
        params: {
          'p_club_id': clubId,
          'p_profile_id': profileId,
        },
      );

      final success = result[0]['success'] as bool;
      if (!success) {
        throw Exception(result[0]['message'] as String);
      }
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Error al revocar acceso: ${e.message}');
    }
  }

  static const _validRoles = {
    'club_president',
    'club_treasurer',
    'club_secretary',
    'team_manager',
    'coach',
    'staff',
    'member',
    'parent_guardian',
    'player',
    'follower',
  };

  void _validateClubId(String clubId) {
    if (clubId.trim().isEmpty) {
      throw ArgumentError('No hay un club activo.');
    }
  }

  String _normalizeEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (!normalized.contains('@') || !normalized.contains('.')) {
      throw ArgumentError('Introduce un email válido.');
    }
    return normalized;
  }

  void _validateRole(String role) {
    if (!_validRoles.contains(role)) {
      throw ArgumentError('El rol seleccionado no es válido.');
    }
  }

  /// Datos demo
  List<ClubMember> _demoMembers() {
    return [
      ClubMember(
        id: '1',
        clubId: 'demo-club',
        profileId: 'demo-user-1',
        role: 'club_president',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
        firstName: 'Juan',
        lastName: 'Pérez',
        email: 'juan@example.com',
      ),
      ClubMember(
        id: '2',
        clubId: 'demo-club',
        profileId: 'demo-user-2',
        role: 'club_treasurer',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        updatedAt: DateTime.now(),
        firstName: 'María',
        lastName: 'García',
        email: 'maria@example.com',
      ),
      ClubMember(
        id: '3',
        clubId: 'demo-club',
        profileId: 'demo-user-3',
        role: 'coach',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        updatedAt: DateTime.now(),
        firstName: 'Luis',
        lastName: 'Martínez',
        email: 'luis@example.com',
      ),
      ClubMember(
        id: '4',
        clubId: 'demo-club',
        profileId: 'demo-user-4',
        role: 'member',
        isActive: false,
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
        updatedAt: DateTime.now(),
        firstName: 'Carlos',
        lastName: 'López',
        email: 'carlos@example.com',
      ),
    ];
  }
}

/// Provider del repositorio
final clubMemberRepositoryProvider = Provider((ref) {
  final supabase = SupabaseService.isConfigured ? Supabase.instance.client : null;
  return ClubMemberRepository(supabase);
});

/// Provider para obtener miembros de un club específico
final clubMembersProvider =
    FutureProvider.family<List<ClubMember>, String>((ref, clubId) {
  return ref.watch(clubMemberRepositoryProvider).getClubMembers(clubId);
});

/// Provider para miembros activos
final activeClubMembersProvider =
    FutureProvider.family<List<ClubMember>, String>((ref, clubId) {
  return ref.watch(clubMemberRepositoryProvider).getActiveClubMembers(clubId);
});