import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/entities/notification.dart';

final notificationsProvider = FutureProvider<List<ClubNotification>>((ref) {
  final clubId = ref.watch(authControllerProvider).clubId;
  if (clubId == null) return Future.value(const []);
  return ref.watch(notificationRepositoryProvider).listNotifications(clubId);
});

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(appBar: AppBar(title: const Text('Notificaciones')), body: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: notifications.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Center(child: Text('No se han podido cargar las notificaciones.')),
      data: (items) => items.isEmpty ? const Center(child: Text('No tienes notificaciones nuevas.')) : ListView.separated(itemCount: items.length, separatorBuilder: (_, index) => const SizedBox(height: 12), itemBuilder: (context, index) => _NotificationCard(notification: items[index])),
    )));
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});
  final ClubNotification notification;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.all(16), leading: CircleAvatar(child: Icon(notification.type == 'event' ? Icons.event_outlined : Icons.notifications_none_outlined)), title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${notification.body}\n${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}'), isThreeLine: true));
}