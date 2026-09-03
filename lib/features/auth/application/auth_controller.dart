import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../clubs/data/repositories/club_repository.dart';

enum AuthStatus { signedOut, signingIn, creatingClub, signedIn, needsClub, error }

class AuthState {
  const AuthState({this.status = AuthStatus.signedOut, this.email, this.errorMessage, this.clubId, this.clubName});

  final AuthStatus status;
  final String? email;
  final String? errorMessage;
  final String? clubId;
  final String? clubName;

  AuthState copyWith({AuthStatus? status, String? email, String? errorMessage, String? clubId, String? clubName, bool clearError = false}) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
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
        await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
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
        await Supabase.instance.client.auth.signUp(email: email, password: password);
      }
      state = state.copyWith(status: AuthStatus.needsClub, email: email, clearError: true);
    } on AuthException catch (error) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'No se ha podido crear la cuenta. Inténtalo de nuevo.');
    }
  }

  Future<void> createClub(String clubName) async {
    state = state.copyWith(status: AuthStatus.creatingClub, clearError: true);
    try {
      final club = await ref.read(clubRepositoryProvider).createClub(publicName: clubName);
      state = state.copyWith(status: AuthStatus.signedIn, clubId: club.id, clubName: club.publicName, clearError: true);
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
