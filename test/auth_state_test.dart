// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): cobertura del estado de recuperación y cambio obligatorio de contraseña.
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_clubes/features/auth/application/auth_controller.dart';

void main() {
  group('AuthState', () {
    test('preserves password recovery state through copyWith', () {
      const state = AuthState(
        status: AuthStatus.signedIn,
        email: 'usuario@example.com',
        passwordRecovery: true,
        mustChangePassword: true,
      );

      final updated = state.copyWith(clearError: true);

      expect(updated.status, AuthStatus.signedIn);
      expect(updated.email, 'usuario@example.com');
      expect(updated.passwordRecovery, isTrue);
      expect(updated.mustChangePassword, isTrue);
      expect(updated.errorMessage, isNull);
    });

    test('can clear both password requirements after successful change', () {
      const state = AuthState(
        status: AuthStatus.signedIn,
        passwordRecovery: true,
        mustChangePassword: true,
      );

      final updated = state.copyWith(
        passwordRecovery: false,
        mustChangePassword: false,
      );

      expect(updated.passwordRecovery, isFalse);
      expect(updated.mustChangePassword, isFalse);
    });
  });
}
