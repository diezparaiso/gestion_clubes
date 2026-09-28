// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): aplica permisos view/manage en acciones de la pantalla.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): mejora responsive; sin cambios de Supabase ni Payments/Stripe.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/services.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Permite copiar el enlace público de la agenda.
import '../../../auth/application/auth_controller.dart';
import '../../../dashboard/presentation/widgets/club_navigation_app_bar.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/entities/event.dart';
import '../../../clubs/data/repositories/club_repository.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Añadida búsqueda y filtros locales de agenda.

final eventsProvider = FutureProvider<List<ClubEvent>>((ref) {
  final clubId = ref.watch(authControllerProvider).clubId;
  if (clubId == null) return Future.value(const []);
  return ref.watch(eventRepositoryProvider).listEvents(clubId);
});

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  final _searchController = TextEditingController();
  bool _publicOnly = false;

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final canManage = ClubRolePermissions.has(ref.watch(authControllerProvider).role, 'events_manage');
    return Scaffold(appBar: const ClubNavigationAppBar(title: 'Eventos'), body: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Agenda del club', style: Theme.of(context).textTheme.headlineMedium),
          IconButton(
            tooltip: 'Copiar enlace público',
            onPressed: () async {
              final clubId = ref.read(authControllerProvider).clubId;
              if (clubId == null) return;
              final club = await ref.read(clubRepositoryProvider).getClubById(clubId);
              final url = Uri.base.replace(path: '/club/' + club.slug + '/events').toString();
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enlace público de la agenda copiado.')),
              );
            },
            icon: const Icon(Icons.link_outlined),
          ),
          if (canManage)
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo evento'),
            ),
        ],
      ),
      const SizedBox(height: 8),
      const Text('Organiza partidos, reuniones y actividades del club.'),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 240, maxWidth: 520),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar evento, ubicación o descripción',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          FilterChip(
            label: const Text('Solo públicos'),
            selected: _publicOnly,
            onSelected: (value) => setState(() => _publicOnly = value),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Expanded(child: events.when(loading: () => const Center(child: CircularProgressIndicator()), error: (error, stack) => const Center(child: Text('No se han podido cargar los eventos.')), data: (items) {
        final query = _searchController.text.trim().toLowerCase();
        final filtered = items.where((event) {
          final text = '${event.title} ${event.location ?? ''} ${event.description}'.toLowerCase();
          return (!_publicOnly || event.visibility == EventVisibility.public) && (query.isEmpty || text.contains(query));
        }).toList();
        return filtered.isEmpty ? Center(child: Text(items.isEmpty ? 'Todavía no hay eventos.' : 'No hay eventos que coincidan.')) : ListView.separated(itemCount: filtered.length, separatorBuilder: (_, index) => const SizedBox(height: 12), itemBuilder: (context, index) => _EventCard(event: filtered[index]));
      })),
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
  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26): El alta permite elegir fecha y hora reales del evento.
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  EventType _type = EventType.event;
  EventVisibility _visibility = EventVisibility.public;
  bool _saving = false;
  late DateTime _startAt;
  late DateTime _endAt;

  @override
  void initState() {
    super.initState();
    _startAt = DateTime.now().add(const Duration(days: 7));
    _endAt = _startAt.add(const Duration(hours: 2));
  }

  @override
  void dispose() { _titleController.dispose(); _descriptionController.dispose(); _locationController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    setState(() => _saving = true);
    try {
      if (!_endAt.isAfter(_startAt)) {
        if (mounted) setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La hora de fin debe ser posterior a la de inicio.')));
        return;
      }
      await ref.read(eventRepositoryProvider).createEvent(clubId: clubId, title: _titleController.text, description: _descriptionController.text, location: _locationController.text, startAt: _startAt, endAt: _endAt, type: _type, visibility: _visibility);
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException {
      if (mounted) setState(() => _saving = false);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Nuevo evento'), content: SizedBox(width: 460, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null), const SizedBox(height: 12), TextFormField(controller: _descriptionController, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Descripción'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null), const SizedBox(height: 12), TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Ubicación')), const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _saving ? null : () async {
                    final date = await showDatePicker(context: context, initialDate: _startAt, firstDate: DateTime.now(), lastDate: DateTime(2050));
                    if (date == null || !mounted) return;
                    setState(() {
                      _startAt = DateTime(date.year, date.month, date.day, _startAt.hour, _startAt.minute);
                      if (!_endAt.isAfter(_startAt)) _endAt = _startAt.add(const Duration(hours: 2));
                    });
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Inicio: ${_startAt.day}/${_startAt.month}/${_startAt.year}'),
                )),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _saving ? null : () async {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startAt));
                    if (time == null || !mounted) return;
                    setState(() {
                      _startAt = DateTime(_startAt.year, _startAt.month, _startAt.day, time.hour, time.minute);
                      if (!_endAt.isAfter(_startAt)) _endAt = _startAt.add(const Duration(hours: 2));
                    });
                  },
                  child: Text('${_startAt.hour.toString().padLeft(2, '0')}:${_startAt.minute.toString().padLeft(2, '0')}'),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _saving ? null : () async {
                    final date = await showDatePicker(context: context, initialDate: _endAt, firstDate: _startAt, lastDate: DateTime(2050));
                    if (date == null || !mounted) return;
                    setState(() => _endAt = DateTime(date.year, date.month, date.day, _endAt.hour, _endAt.minute));
                  },
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text('Fin: ${_endAt.day}/${_endAt.month}/${_endAt.year}'),
                )),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _saving ? null : () async {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_endAt));
                    if (time == null || !mounted) return;
                    setState(() => _endAt = DateTime(_endAt.year, _endAt.month, _endAt.day, time.hour, time.minute));
                  },
                  child: Text('${_endAt.hour.toString().padLeft(2, '0')}:${_endAt.minute.toString().padLeft(2, '0')}'),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<EventType>(initialValue: _type, decoration: const InputDecoration(labelText: 'Tipo'), items: const [DropdownMenuItem(value: EventType.match, child: Text('Partido')), DropdownMenuItem(value: EventType.tournament, child: Text('Torneo')), DropdownMenuItem(value: EventType.meeting, child: Text('Reunión')), DropdownMenuItem(value: EventType.event, child: Text('Actividad')), DropdownMenuItem(value: EventType.fundraiser, child: Text('Recaudación')), DropdownMenuItem(value: EventType.other, child: Text('Otro'))], onChanged: (value) => setState(() => _type = value ?? EventType.event)), DropdownButtonFormField<EventVisibility>(initialValue: _visibility, decoration: const InputDecoration(labelText: 'Visibilidad'), items: const [DropdownMenuItem(value: EventVisibility.public, child: Text('Público')), DropdownMenuItem(value: EventVisibility.clubOnly, child: Text('Solo club')), DropdownMenuItem(value: EventVisibility.private, child: Text('Privado'))], onChanged: (value) => setState(() => _visibility = value ?? EventVisibility.public))])))), actions: [TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')), FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'))]);
}