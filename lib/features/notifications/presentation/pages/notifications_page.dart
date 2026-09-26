import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_delivery_repository.dart';
import '../../domain/entities/notification_delivery.dart';

/// Provider para obtener las entregas de notificaciones del usuario actual
final notificationDeliveriesProvider =
    FutureProvider<List<NotificationDelivery>>((ref) {
  return ref
      .watch(notificationDeliveryRepositoryProvider)
      .getAllDeliveries();
});

/// Provider para obtener solo las no leídas
final unreadNotificationsProvider =
    FutureProvider<List<NotificationDelivery>>((ref) {
  return ref
      .watch(notificationDeliveryRepositoryProvider)
      .getUnreadDeliveries();
});

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveries = ref.watch(notificationDeliveriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          ref.watch(unreadNotificationsProvider).when(
            data: (unread) => unread.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: TextButton(
                        onPressed: () async {
                          await ref
                              .read(notificationDeliveryRepositoryProvider)
                              .markAllAsRead();
                          ref.invalidate(notificationDeliveriesProvider);
                          ref.invalidate(unreadNotificationsProvider);
                        },
                        child: Text('Marcar todas (${unread.length}) como leídas'),
                      ),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: deliveries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error al cargar notificaciones: $error'),
          ),
          data: (items) => items.isEmpty
              ? const Center(
                  child: Text('No tienes notificaciones.'),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _NotificationDeliveryCard(
                    delivery: items[index],
                    onMarkAsRead: () async {
                      await ref
                          .read(notificationDeliveryRepositoryProvider)
                          .markAsRead(items[index].id);
                      ref.invalidate(notificationDeliveriesProvider);
                      ref.invalidate(unreadNotificationsProvider);
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _NotificationDeliveryCard extends StatelessWidget {
  final NotificationDelivery delivery;
  final VoidCallback onMarkAsRead;

  const _NotificationDeliveryCard({
    required this.delivery,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: delivery.isRead ? Colors.white : Colors.blue.shade50,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor:
              delivery.isRead ? Colors.grey.shade300 : Colors.blue,
          child: Icon(
            delivery.isRead
                ? Icons.done_outlined
                : Icons.notifications_none_outlined,
            color: delivery.isRead ? Colors.grey.shade700 : Colors.white,
          ),
        ),
        title: Text(
          delivery.title ?? (delivery.isRead ? 'Notificación leída' : 'Notificación nueva'),
          style: TextStyle(
            fontWeight: delivery.isRead ? FontWeight.w500 : FontWeight.w800,
            color: delivery.isRead ? Colors.grey.shade600 : Colors.black,
          ),
        ),
        subtitle: Text(
          '${delivery.body ?? ''}\n${delivery.createdAt.day}/${delivery.createdAt.month}/${delivery.createdAt.year} '
          '${delivery.createdAt.hour}:${delivery.createdAt.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: delivery.isRead ? Colors.grey.shade500 : Colors.black54,
          ),
        ),
        trailing: !delivery.isRead
            ? IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Marcar como leída',
                onPressed: onMarkAsRead,
              )
            : null,
      ),
    );
  }
}