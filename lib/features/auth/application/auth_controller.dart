import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../clubs/data/repositories/club_repository.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): completa recuperación de contraseña y sesión de recuperación.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): añade permiso de gestión de patrocinadores para el presidente.

enum AuthStatus { signedOut, signingIn, creatingClub, signedIn, needsClub, error }

class ClubAccess {
  const ClubAccess({
    required this.clubId,
    required this.clubName,
    required this.slug,
    required this.role,
  });

  final String clubId;
  final String clubName;
  final String slug;
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
      .select('club_id, role, clubs!inner(id, public_name, slug)')
      .eq('profile_id', userId)
      .eq('is_active', true)
      .order('created_at');

  return rows.map((row) {
    final club = row['clubs'] as Map<String, dynamic>;
    return ClubAccess(
      clubId: row['club_id'] as String,
      clubName: club['public_name'] as String,
      slug: club['slug'] as String,
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
    this.duplicateClub,
    this.mustChangePassword = false,
    this.passwordRecovery = false,
  });

  final AuthStatus status;
  final String? email;
  final String? errorMessage;
  final String? clubId;
  final String? clubName;
  final String? role;
  final ClubAccess? duplicateClub;
  final bool mustChangePassword;
  final bool passwordRecovery;

  String get roleLabel => ClubAccess(
    clubId: clubId ?? '',
    clubName: clubName ?? '',
    slug: '',
    role: role ?? '',
  ).roleLabel;

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? errorMessage,
    String? clubId,
    String? clubName,
    String? role,
    ClubAccess? duplicateClub,
    bool? mustChangePassword,
    bool? passwordRecovery,
    bool clearError = false,
    bool clearDuplicateClub = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      role: role ?? this.role,
      duplicateClub: clearDuplicateClub
          ? null
          : duplicateClub ?? this.duplicateClub,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      passwordRecovery: passwordRecovery ?? this.passwordRecovery,
    );
  }
}


class ClubRolePermissions {
  const ClubRolePermissions._();

  static const Map<String, Set<String>> _permissions = {
    'club_president': {'dashboard_view','members_view','members_manage','teams_view','teams_manage','players_view','players_manage','finance_view','finance_manage','raffles_view','raffles_manage','news_view','news_manage','events_view','events_manage','notifications_view','club_settings_view','club_settings_manage','access_manage','sponsors_manage'},
    'club_treasurer': {'dashboard_view','finance_view','finance_manage','notifications_view'},
    'club_secretary': {'dashboard_view','members_view','members_manage','news_view','news_manage','events_view','events_manage','notifications_view'},
    'team_manager': {'dashboard_view','teams_view','players_view','players_manage','notifications_view'},
    'coach': {'dashboard_view','teams_view','players_view','notifications_view'},
    'staff': {'dashboard_view','notifications_view'},
    'member': {'dashboard_view','members_view','notifications_view'},
    'parent_guardian': {'dashboard_view','players_view','notifications_view'},
    'player': {'dashboard_view','players_view','notifications_view'},
    'follower': {'dashboard_view','notifications_view'},
  };

  static bool has(String? role, String permission) => _permissions[role]?.contains(permission) ?? false;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    if (SupabaseService.isConfigured) {
      final subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          state = state.copyWith(
            status: AuthStatus.signedIn,
            mustChangePassword: true,
            passwordRecovery: true,
            clearError: true,
          );
        }
      });
      ref.onDispose(subscription.cancel);

      if (Supabase.instance.client.auth.currentSession != null) {
        return const AuthState(status: AuthStatus.needsClub);
      }
    }
    return const AuthState();
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.signingIn, clearError: true);
    try {
      if (SupabaseService.isConfigured) {
        await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      }
      state = state.copyWith(
        status: AuthStatus.needsClub,
        email: email,
        passwordRecovery: false,
        mustChangePassword: false,
        clearError: true,
      );
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
        await Supabase.instance.client.auth.signUp(email: email, password: password);
      }
      state = state.copyWith(
        status: AuthStatus.needsClub,
        email: email,
        passwordRecovery: false,
        mustChangePassword: false,
        clearError: true,
      );
    } on AuthException catch (error) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'No se ha podido crear la cuenta. Inténtalo de nuevo.');
    }
  }

  Future<void> selectClub(ClubAccess club) async {
    var mustChangePassword = false;
    if (SupabaseService.isConfigured) {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('must_change_password')
          .eq('id', Supabase.instance.client.auth.currentUser!.id)
          .maybeSingle();
      mustChangePassword = profile?['must_change_password'] == true;
    }
    state = state.copyWith(
      status: AuthStatus.signedIn,
      clubId: club.clubId,
      clubName: club.clubName,
      role: club.role,
      mustChangePassword: mustChangePassword,
      clearError: true,
    );
  }

  Future<void> createClub(String clubName) async {
    if (state.status == AuthStatus.creatingClub) return;
    final slug = ClubRepository.normalizeSlug(clubName);
    state = state.copyWith(
      status: AuthStatus.creatingClub,
      clearError: true,
      clearDuplicateClub: true,
    );
    try {
      final club = await ref.read(clubRepositoryProvider).createClub(publicName: clubName);
      state = state.copyWith(
        status: AuthStatus.signedIn,
        clubId: club.id,
        clubName: club.publicName,
        role: 'club_president',
        mustChangePassword: false,
        clearError: true,
        clearDuplicateClub: true,
      );
    } catch (error) {
      await _handleClubCreationFailure(error, slug);
    }
  }

  Future<void> _handleClubCreationFailure(Object error, String slug) async {
    var errorMessage = 'No se ha podido crear el club. Inténtalo de nuevo.';
    var slugConflict = false;
    if (error is PostgrestException) {
      slugConflict = ClubRepository.isSlugConflict(
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint,
      );
      errorMessage = ClubRepository.creationErrorMessage(
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint,
      );
    } else if (error is AuthException) {
      errorMessage = 'Tu sesión ha expirado. Inicia sesión de nuevo.';
    } else if (error is FormatException) {
      errorMessage =
          'El nombre debe incluir letras o números para crear un identificador válido.';
    }

    ClubAccess? duplicateClub;
    var refreshFailed = false;
    ref.invalidate(availableClubsProvider);
    try {
      final clubs = await ref.read(availableClubsProvider.future);
      if (slugConflict) {
        for (final club in clubs) {
          if (club.role == 'club_president' && club.slug == slug) {
            duplicateClub = club;
            break;
          }
        }
      }
    } on Exception {
      refreshFailed = true;
    }

    if (refreshFailed) {
      errorMessage =
          '$errorMessage No se pudo actualizar la lista de clubes; vuelve a intentarlo.';
    }
    state = state.copyWith(
      status: AuthStatus.needsClub,
      errorMessage: errorMessage,
      duplicateClub: duplicateClub,
      clearDuplicateClub: duplicateClub == null,
    );
  }

  void clearPasswordChangeRequirement() {
    state = state.copyWith(mustChangePassword: false, passwordRecovery: false);
  }

  Future<void> signOut() async {
    if (SupabaseService.isConfigured) await Supabase.instance.client.auth.signOut();
    state = const AuthState();
  }
}
