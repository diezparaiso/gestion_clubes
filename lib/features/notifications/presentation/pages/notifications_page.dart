import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/widgets/club_navigation_app_bar.dart';
import '../../../auth/application/auth_controller.dart';

import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/notification_delivery_repository.dart';
import '../../domain/entities/notification_delivery.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Añadido filtrado local de notificaciones.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): cierre UX del módulo, responsive y manejo visible de errores.

/// Provider para obtener las entregas de notificaciones del usuario actual
final notificationsProvider = FutureProvider<List<NotificationDelivery>>((ref) {
  return ref.watch(notificationDeliveryRepositoryProvider).getAllDeliveries();
});

final notificationDeliveriesProvider = notificationsProvider;

/// Provider para obtener solo las no leídas
final unreadNotificationsProvider = FutureProvider<List<NotificationDelivery>>((
  ref,
) {
  return ref
      .watch(notificationDeliveryRepositoryProvider)
      .getUnreadDeliveries();
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final unread = await ref
      .watch(notificationDeliveryRepositoryProvider)
      .getUnreadDeliveries();
  return unread.length;
});

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _onlyUnread = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final deliveries = ref.watch(notificationsProvider);
    final canCreate = ClubRolePermissions.canCreateNotifications(auth.role);

    return Scaffold(
      appBar: ClubNavigationAppBar(
        title: 'Notificaciones',
        actions: [
          ref
              .watch(unreadNotificationsProvider)
              .when(
                data: (unread) => unread.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: TextButton(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(
                                      notificationDeliveryRepositoryProvider,
                                    )
                                    .markAllAsRead();
                                ref.invalidate(notificationsProvider);
                                ref.invalidate(unreadNotificationsProvider);
                                ref.invalidate(
                                  unreadNotificationsCountProvider,
                                );
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'No se han podido marcar todas: $error',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Marcar todas (${unread.length}) como leídas',
                            ),
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
        child: Column(
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 240,
                    maxWidth: 600,
                  ),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Buscar notificación',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Solo no leídas'),
                  selected: _onlyUnread,
                  onSelected: (value) => setState(() => _onlyUnread = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: deliveries.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'No se han podido cargar las notificaciones.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text('$error', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            ref.invalidate(notificationsProvider);
                            ref.invalidate(unreadNotificationsProvider);
                            ref.invalidate(unreadNotificationsCountProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) {
                  final filtered = items.where((item) {
                    final matchesUnread = !_onlyUnread || !item.isRead;
                    final text = '${item.title ?? ''} ${item.body ?? ''}'
                        .toLowerCase();
                    return matchesUnread &&
                        (_query.isEmpty || text.contains(_query));
                  }).toList();
                  return filtered.isEmpty
                      ? Center(
                          child: Text(
                            items.isEmpty
                                ? 'No tienes notificaciones.'
                                : 'No hay notificaciones que coincidan.',
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => _NotificationDeliveryCard(
                            delivery: filtered[index],
                            onMarkAsRead: () async {
                              try {
                                await ref
                                    .read(
                                      notificationDeliveryRepositoryProvider,
                                    )
                                    .markAsRead(filtered[index].id);
                                ref.invalidate(notificationsProvider);
                                ref.invalidate(unreadNotificationsProvider);
                                ref.invalidate(
                                  unreadNotificationsCountProvider,
                                );
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'No se ha podido marcar la notificación: $error',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              key: const ValueKey('create-notification-fab'),
              tooltip: 'Crear notificación',
              onPressed: () async {
                final created = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) =>
                      _CreateNotificationDialog(clubId: auth.clubId ?? ''),
                );
                if (created != true || !context.mounted) return;
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationsProvider);
                ref.invalidate(unreadNotificationsCountProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notificación enviada correctamente.'),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _CreateNotificationDialog extends ConsumerStatefulWidget {
  const _CreateNotificationDialog({required this.clubId});

  final String clubId;

  @override
  ConsumerState<_CreateNotificationDialog> createState() =>
      _CreateNotificationDialogState();
}

class _CreateNotificationDialogState
    extends ConsumerState<_CreateNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _type = 'news';
  String _target = 'all_members';
  bool _isSubmitting = false;
  String? _errorMessage;

  static const _types = <({String value, String label})>[
    (value: 'news', label: 'Noticia'),
    (value: 'event', label: 'Evento'),
    (value: 'raffle', label: 'Rifa'),
    (value: 'system', label: 'Sistema'),
    (value: 'other', label: 'Otro'),
  ];

  static const _targets = <({String value, String label})>[
    (value: 'all_members', label: 'Todos los miembros'),
    (value: 'managers', label: 'Responsables del club'),
    (value: 'members', label: 'Socios'),
    (value: 'staff', label: 'Personal'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(notificationRepositoryProvider)
          .createNotification(
            clubId: widget.clubId,
            title: _titleController.text,
            body: _bodyController.text,
            type: _type,
            target: _target,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'No se ha podido enviar la notificación. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nueva notificación',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(labelText: 'Título'),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe un título.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(labelText: 'Mensaje'),
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe un mensaje.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: _types
                    .map(
                      (type) => DropdownMenuItem(
                        value: type.value,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _type = value);
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _target,
                decoration: const InputDecoration(labelText: 'Destinatarios'),
                items: _targets
                    .map(
                      (target) => DropdownMenuItem(
                        value: target.value,
                        child: Text(target.label),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _target = value);
                      },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar notificación'),
              ),
            ],
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
          backgroundColor: delivery.isRead ? Colors.grey.shade300 : Colors.blue,
          child: Icon(
            delivery.isRead
                ? Icons.done_outlined
                : Icons.notifications_none_outlined,
            color: delivery.isRead ? Colors.grey.shade700 : Colors.white,
          ),
        ),
        title: Text(
          delivery.title ??
              (delivery.isRead ? 'Notificación leída' : 'Notificación nueva'),
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
