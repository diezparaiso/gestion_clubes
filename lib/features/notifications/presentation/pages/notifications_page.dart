import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return Scaffold(appBar: AppBar(title: const Text('Notificaciones'), actions: [IconButton(onPressed: () => _showCreateDialog(context, ref), tooltip: 'Nueva notificación', icon: const Icon(Icons.add_alert_outlined))]), body: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: notifications.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Center(child: Text('No se han podido cargar las notificaciones.')),
      data: (items) => items.isEmpty ? const Center(child: Text('No tienes notificaciones nuevas.')) : ListView.separated(itemCount: items.length, separatorBuilder: (_, index) => const SizedBox(height: 12), itemBuilder: (context, index) => _NotificationCard(notification: items[index])),
    )));
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => const _CreateNotificationDialog());
    if (saved == true) ref.invalidate(notificationsProvider);
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});
  final ClubNotification notification;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.all(16), leading: CircleAvatar(child: Icon(notification.type == 'event' ? Icons.event_outlined : Icons.notifications_none_outlined)), title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${notification.body}\n${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}'), isThreeLine: true));
}

class _CreateNotificationDialog extends ConsumerStatefulWidget {
  const _CreateNotificationDialog();
  @override
  ConsumerState<_CreateNotificationDialog> createState() => _CreateNotificationDialogState();
}

class _CreateNotificationDialogState extends ConsumerState<_CreateNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _type = 'system';
  String _target = 'all_members';
  bool _saving = false;

  @override
  void dispose() { _titleController.dispose(); _bodyController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(notificationRepositoryProvider).createNotification(clubId: clubId, title: _titleController.text, body: _bodyController.text, type: _type, target: _target);
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException {
      if (mounted) setState(() => _saving = false);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Nueva notificación'), content: SizedBox(width: 440, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null), const SizedBox(height: 12), TextFormField(controller: _bodyController, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Mensaje'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null), const SizedBox(height: 12), DropdownButtonFormField<String>(initialValue: _type, decoration: const InputDecoration(labelText: 'Tipo'), items: const [DropdownMenuItem(value: 'news', child: Text('Noticias')), DropdownMenuItem(value: 'event', child: Text('Eventos')), DropdownMenuItem(value: 'raffle', child: Text('Rifas')), DropdownMenuItem(value: 'system', child: Text('Sistema')), DropdownMenuItem(value: 'other', child: Text('Otro'))], onChanged: (value) => setState(() => _type = value ?? 'system')), DropdownButtonFormField<String>(initialValue: _target, decoration: const InputDecoration(labelText: 'Destinatarios'), items: const [DropdownMenuItem(value: 'all_members', child: Text('Todos los miembros')), DropdownMenuItem(value: 'managers', child: Text('Responsables')), DropdownMenuItem(value: 'members', child: Text('Socios')), DropdownMenuItem(value: 'staff', child: Text('Personal'))], onChanged: (value) => setState(() => _target = value ?? 'all_members'))])))), actions: [TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')), FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Publicar'))]);
}