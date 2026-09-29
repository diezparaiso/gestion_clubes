// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): cobertura de permisos requeridos por ruta.
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_clubes/app/router.dart';

void main() {
  group('permissionForLocation', () {
    test('requires view permissions for protected top-level routes', () {
      expect(permissionForLocation('/dashboard'), 'dashboard_view');
      expect(permissionForLocation('/my-raffles'), 'dashboard_view');
      expect(permissionForLocation('/members'), 'members_view');
      expect(permissionForLocation('/teams'), 'teams_view');
      expect(permissionForLocation('/finance'), 'finance_view');
      expect(permissionForLocation('/raffles'), 'raffles_view');
      expect(permissionForLocation('/news'), 'news_view');
      expect(permissionForLocation('/events'), 'events_view');
      expect(permissionForLocation('/notifications'), 'notifications_view');
      expect(permissionForLocation('/settings'), 'club_settings_view');
    });

    test('uses players permission for team player routes', () {
      expect(permissionForLocation('/teams/team-1/players'), 'players_view');
      expect(permissionForLocation('/teams/team-1/players/edit'), 'players_view');
    });

    test('keeps staff routes under teams permission', () {
      expect(permissionForLocation('/teams/team-1/staff'), 'teams_view');
    });

    test('protects access management separately', () {
      expect(permissionForLocation('/settings/access'), 'access_manage');
      expect(permissionForLocation('/raffles/raffle-1'), 'raffles_view');
    });

    test('leaves public and unknown locations without a permission requirement', () {
      expect(permissionForLocation('/login'), isNull);
      expect(permissionForLocation('/register'), isNull);
      expect(permissionForLocation('/privacy'), isNull);
      expect(permissionForLocation('/profile'), isNull);
      expect(permissionForLocation('/profile/password'), isNull);
      expect(permissionForLocation('/club/demo'), isNull);
      expect(permissionForLocation('/club/demo/news'), isNull);
      expect(permissionForLocation('/club/demo/events'), isNull);
      expect(permissionForLocation('/r/demo/sorteo'), isNull);
      expect(permissionForLocation('/unknown'), isNull);
    });
  });
}
