import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_clubes/features/notifications/data/repositories/notification_repository.dart';

void main() {
  test('notification creation rejects personal and unknown targets', () async {
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
  });
}
