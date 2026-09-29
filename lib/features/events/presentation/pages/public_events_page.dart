import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/event_repository.dart';
import '../../domain/entities/event.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Muestra fecha y hora reales en la agenda pública.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): añade navegación pública consistente y acceso al login.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-29): añade reintento ante errores de carga pública.
class PublicEventsPage extends StatefulWidget {
  const PublicEventsPage({super.key, required this.clubSlug});
  final String clubSlug;

  @override
  State<PublicEventsPage> createState() => _PublicEventsPageState();
}

class _PublicEventsPageState extends State<PublicEventsPage> {
  late Future<List<ClubEvent>> _events;

  @override
  void initState() {
    super.initState();
    _events = EventRepository().listPublicEvents(widget.clubSlug);
  }

  String _formatDateTime(DateTime value) {
    final date = '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    final time = '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }

  void _retry() {
    setState(() {
      _events = EventRepository().listPublicEvents(widget.clubSlug);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Eventos del club'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Acceder'),
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<ClubEvent>>(
          future: _events,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return _PublicLoadError(message: 'No se han podido cargar los eventos.', onRetry: _retry);
            final events = snapshot.data!;
            if (events.isEmpty) return const Center(child: Text('Todavía no hay eventos públicos.'));
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: events.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                final endText = ' — ${_formatDateTime(event.endAt)}';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: Text(event.title),
                    subtitle: Text(
                      '${_formatDateTime(event.startAt)}$endText · ${event.location ?? 'Sin ubicación'}\n${event.description}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      );
}

class _PublicLoadError extends StatelessWidget {
  const _PublicLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
