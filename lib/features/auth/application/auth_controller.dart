import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../clubs/data/repositories/club_repository.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): permite recuperar clubes existentes y seleccionar el acceso del usuario.

enum AuthStatus { signedOut, signingIn, creatingClub, signedIn, needsClub, error }

class ClubAccess {
  const ClubAccess({
    required this.clubId,
    required this.clubName,
    required this.role,
  });

  final String clubId;
  final String clubName;
  final String role;

  String get roleLabel => switch (role) {
    'club_president' => 'Presidente',
    'club_treasurer' => 'Tesorero/a',
    'club_secretary' => 'Secretario/a',
    'team_manager' => 'Delegado/a',
    'coach' => 'Entrenador/a',
    'staff' => 'Personal',
    'member' => 'Socio/a',
    'parent_guardian' => 'Padre/madre/tutor',
    'player' => 'Jugador/a',
    'follower' => 'Seguidor/a',
    _ => role,
  };
}

final availableClubsProvider = FutureProvider<List<ClubAccess>>((ref) async {
  if (!SupabaseService.isConfigured) return const [];
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return const [];

  final rows = await Supabase.instance.client
      .from('club_memberships')
      .select('club_id, role, clubs!inner(id, public_name)')
      .eq('profile_id', userId)
      .eq('is_active', true)
      .order('created_at');

  return rows.map((row) {
    final club = row['clubs'] as Map<String, dynamic>;
    return ClubAccess(
      clubId: row['club_id'] as String,
      clubName: club['public_name'] as String,
      role: row['role'] as String,
    );
  }).toList();
});

class AuthState {
  const AuthState({
    this.status = AuthStatus.signedOut,
    this.email,
    this.errorMessage,
    this.clubId,
    this.clubName,
    this.role,
  });

  final AuthStatus status;
  final String? email;
  final String? errorMessage;
  final String? clubId;
  final String? clubName;
  final String? role;

  String get roleLabel => ClubAccess(
    clubId: clubId ?? '',
    clubName: clubName ?? '',
    role: role ?? '',
  ).roleLabel;

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? errorMessage,
    String? clubId,
    String? clubName,
    String? role,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      role: role ?? this.role,
    );
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    if (SupabaseService.isConfigured && Supabase.instance.client.auth.currentSession != null) {
      return const AuthState(status: AuthStatus.needsClub);
    }
    return const AuthState();
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.signingIn, clearError: true);
    try {
      if (SupabaseService.isConfigured) {
        await Supabase.instance.client.auth.signInWithPassword(email, password);
      }
      state = state.copyWith(status: AuthStatus.needsClub, email: email, clearError: true);
    } on AuthException catch (error) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'No se ha podido iniciar sesión. Inténtalo de nuevo.');
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(status: AuthStatus.signingIn, clearError: true);
    try {
      if (SupabaseService.isConfigured) {
        await Supabase.instance.client.auth.signUp(email, password);
      }
      state = state.copyWith(status: AuthStatus.needsClub, email: email, clearError: true);
    } on AuthException catch (error) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'No se ha podido crear la cuenta. Inténtalo de nuevo.');
    }
  }

  Future<void> selectClub(ClubAccess club) async {
    state = state.copyWith(
      status: AuthStatus.signedIn,
      clubId: club.clubId,
      clubName: club.clubName,
      role: club.role,
      clearError: true,
    );
  }

  Future<void> createClub(String clubName) async {
    state = state.copyWith(status: AuthStatus.creatingClub, clearError: true);
    try {
      final club = await ref.read(clubRepositoryProvider).createClub(publicName: clubName);
      state = state.copyWith(
        status: AuthStatus.signedIn,
        clubId: club.id,
        clubName: club.publicName,
        role: 'club_president',
        clearError: true,
      );
    } on PostgrestException catch (error) {
      state = state.copyWith(status: AuthStatus.needsClub, errorMessage: error.message);
    } on AuthException catch (error) {
      state = state.copyWith(status: AuthStatus.needsClub, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.needsClub, errorMessage: 'No se ha podido crear el club. Inténtalo de nuevo.');
    }
  }

  Future<void> signOut() async {
    if (SupabaseService.isConfigured) await Supabase.instance.client.auth.signOut();
    state = const AuthState();
  }
}
