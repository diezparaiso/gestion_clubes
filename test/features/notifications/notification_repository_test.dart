import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_clubes/features/notifications/data/repositories/notification_repository.dart';

void main() {
  test('notification creation rejects unsupported types and targets', () async {
    final repository = NotificationRepository();

    for (final target in ['profile', 'everyone']) {
      await expectLater(
        repository.createNotification(
          clubId: 'club-1',
          title: 'Aviso',
          body: 'Contenido',
          type: 'other',
          target: target,
        ),
        throwsA(isA<FormatException>()),
      );
    }
    await expectLater(
      repository.createNotification(
        clubId: 'club-1',
        title: 'Aviso',
        body: 'Contenido',
        type: 'invalid',
        target: 'all_members',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'notification creation calls the RPC and builds the returned entity',
    () async {
      Map<String, dynamic>? sentParams;
      final repository = NotificationRepository(
        createNotificationRpc: (params) async {
          sentParams = params;
          return 'notification-from-rpc';
        },
      );

      final notification = await repository.createNotification(
        clubId: 'club-1',
        title: '  Aviso  ',
        body: '  Contenido  ',
        type: 'news',
        target: 'all_members',
      );

      expect(sentParams, {
        'p_club_id': 'club-1',
        'p_title': 'Aviso',
        'p_body': 'Contenido',
        'p_type': 'news',
        'p_target': 'all_members',
      });
      expect(notification.id, 'notification-from-rpc');
      expect(notification.title, 'Aviso');
      expect(notification.body, 'Contenido');
    },
  );
}
