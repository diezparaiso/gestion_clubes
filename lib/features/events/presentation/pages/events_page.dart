import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/entities/event.dart';

final eventsProvider = FutureProvider<List<ClubEvent>>((ref) {
  final clubId = ref.watch(authControllerProvider).clubId;
  if (clubId == null) return Future.value(const []);
  return ref.watch(eventRepositoryProvider).listEvents(clubId);
});

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    return Scaffold(appBar: AppBar(title: const Text('Eventos')), body: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Agenda del club', style: Theme.of(context).textTheme.headlineMedium)), FilledButton.icon(onPressed: () => _showCreateDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Nuevo evento'))]),
      const SizedBox(height: 8),
      const Text('Organiza partidos, reuniones y actividades del club.'),
      const SizedBox(height: 24),
      Expanded(child: events.when(loading: () => const Center(child: CircularProgressIndicator()), error: (error, stack) => const Center(child: Text('No se han podido cargar los eventos.')), data: (items) => items.isEmpty ? const Center(child: Text('Todavía no hay eventos.')) : ListView.separated(itemCount: items.length, separatorBuilder: (_, index) => const SizedBox(height: 12), itemBuilder: (context, index) => _EventCard(event: items[index])))),
    ])));
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => const _CreateEventDialog());
    if (saved == true) ref.invalidate(eventsProvider);
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final ClubEvent event;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.all(16), leading: const CircleAvatar(child: Icon(Icons.event_outlined)), title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${_dateLabel(event.startAt)} · ${event.location ?? 'Sin ubicación'}\n${event.description}', maxLines: 2, overflow: TextOverflow.ellipsis), isThreeLine: true, trailing: Chip(label: Text(event.visibility == EventVisibility.public ? 'Público' : 'Interno'), side: BorderSide.none)));

  static String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _CreateEventDialog extends ConsumerStatefulWidget {
  const _CreateEventDialog();
  @override
  ConsumerState<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends ConsumerState<_CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  EventType _type = EventType.event;
  EventVisibility _visibility = EventVisibility.public;
  bool _saving = false;

  @override
  void dispose() { _titleController.dispose(); _descriptionController.dispose(); _locationController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    setState(() => _saving = true);
    try {
      final startAt = DateTime.now().add(const Duration(days: 7));
      await ref.read(eventRepositoryProvider).createEvent(clubId: clubId, title: _titleController.text, description: _descriptionController.text, location: _locationController.text, startAt: startAt, endAt: startAt.add(const Duration(hours: 2)), type: _type, visibility: _visibility);
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException {
      if (mounted) setState(() => _saving = false);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Nuevo evento'), content: SizedBox(width: 460, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null), const SizedBox(height: 12), TextFormField(controller: _descriptionController, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Descripción'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null), const SizedBox(height: 12), TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Ubicación')), const SizedBox(height: 12), DropdownButtonFormField<EventType>(initialValue: _type, decoration: const InputDecoration(labelText: 'Tipo'), items: const [DropdownMenuItem(value: EventType.match, child: Text('Partido')), DropdownMenuItem(value: EventType.tournament, child: Text('Torneo')), DropdownMenuItem(value: EventType.meeting, child: Text('Reunión')), DropdownMenuItem(value: EventType.event, child: Text('Actividad')), DropdownMenuItem(value: EventType.fundraiser, child: Text('Recaudación')), DropdownMenuItem(value: EventType.other, child: Text('Otro'))], onChanged: (value) => setState(() => _type = value ?? EventType.event)), DropdownButtonFormField<EventVisibility>(initialValue: _visibility, decoration: const InputDecoration(labelText: 'Visibilidad'), items: const [DropdownMenuItem(value: EventVisibility.public, child: Text('Público')), DropdownMenuItem(value: EventVisibility.clubOnly, child: Text('Solo club')), DropdownMenuItem(value: EventVisibility.private, child: Text('Privado'))], onChanged: (value) => setState(() => _visibility = value ?? EventVisibility.public))])))), actions: [TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')), FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'))]);
}