// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): cobertura básica de la matriz de permisos por rol.
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_clubes/features/auth/application/auth_controller.dart';

void main() {
  group('ClubRolePermissions', () {
    test('president has full club management permissions', () {
      const role = 'club_president';

      expect(ClubRolePermissions.has(role, 'dashboard_view'), isTrue);
      expect(ClubRolePermissions.has(role, 'members_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'teams_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'players_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'finance_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'raffles_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'news_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'events_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'club_settings_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'access_manage'), isTrue);
    });

    test('treasurer cannot manage members or access', () {
      const role = 'club_treasurer';

      expect(ClubRolePermissions.has(role, 'finance_view'), isTrue);
      expect(ClubRolePermissions.has(role, 'finance_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'members_view'), isFalse);
      expect(ClubRolePermissions.has(role, 'members_manage'), isFalse);
      expect(ClubRolePermissions.has(role, 'access_manage'), isFalse);
    });

    test('secretary manages members, news and events but not finance', () {
      const role = 'club_secretary';

      expect(ClubRolePermissions.has(role, 'members_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'news_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'events_manage'), isTrue);
      expect(ClubRolePermissions.has(role, 'finance_view'), isFalse);
      expect(ClubRolePermissions.has(role, 'finance_manage'), isFalse);
      expect(ClubRolePermissions.has(role, 'access_manage'), isFalse);
    });

    test('team roles can view teams and players but cannot manage club access', () {
      for (final role in const ['team_manager', 'coach']) {
        expect(ClubRolePermissions.has(role, 'teams_view'), isTrue);
        expect(ClubRolePermissions.has(role, 'players_view'), isTrue);
        expect(ClubRolePermissions.has(role, 'players_manage'), isTrue);
        expect(ClubRolePermissions.has(role, 'finance_manage'), isFalse);
        expect(ClubRolePermissions.has(role, 'access_manage'), isFalse);
      }
    });

    test('basic member roles do not gain management permissions', () {
      for (final role in const ['staff', 'member', 'parent_guardian', 'player', 'follower']) {
        expect(ClubRolePermissions.has(role, 'members_manage'), isFalse);
        expect(ClubRolePermissions.has(role, 'teams_manage'), isFalse);
        expect(ClubRolePermissions.has(role, 'finance_manage'), isFalse);
        expect(ClubRolePermissions.has(role, 'raffles_manage'), isFalse);
        expect(ClubRolePermissions.has(role, 'access_manage'), isFalse);
      }
    });

    test('unknown role or permission is denied by default', () {
      expect(ClubRolePermissions.has('unknown_role', 'dashboard_view'), isFalse);
      expect(ClubRolePermissions.has(null, 'dashboard_view'), isFalse);
      expect(ClubRolePermissions.has('member', 'unknown_permission'), isFalse);
    });
  });
}
