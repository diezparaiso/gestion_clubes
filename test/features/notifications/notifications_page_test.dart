import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_clubes/features/auth/application/auth_controller.dart';
import 'package:gestion_clubes/features/notifications/presentation/pages/notifications_page.dart';

class _TestAuthController extends AuthController {
  _TestAuthController(this.testRole);

  final String testRole;

  @override
  AuthState build() =>
      AuthState(status: AuthStatus.signedIn, clubId: 'qa-club', role: testRole);
}

void main() {
  Future<void> pumpPage(WidgetTester tester, String role) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController(role)),
          notificationsProvider.overrideWith((ref) async => const []),
          unreadNotificationsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: NotificationsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows create notification FAB for club president', (
    tester,
  ) async {
    await pumpPage(tester, 'club_president');

    expect(
      find.byKey(const ValueKey('create-notification-fab')),
      findsOneWidget,
    );
  });

  testWidgets('hides create notification FAB for coach', (tester) async {
    await pumpPage(tester, 'coach');

    expect(find.byKey(const ValueKey('create-notification-fab')), findsNothing);
  });
}
