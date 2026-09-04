import 'package:flutter/material.dart';

import '../../data/repositories/event_repository.dart';
import '../../domain/entities/event.dart';

class PublicEventsPage extends StatefulWidget {
  const PublicEventsPage({super.key, required this.clubSlug});
  final String clubSlug;
  @override
  State<PublicEventsPage> createState() => _PublicEventsPageState();
}

class _PublicEventsPageState extends State<PublicEventsPage> {
  late final Future<List<ClubEvent>> _events;
  @override
  void initState() { super.initState(); _events = EventRepository().listPublicEvents(widget.clubSlug); }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Eventos del club')), body: FutureBuilder<List<ClubEvent>>(future: _events, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text('No se han podido cargar los eventos.'));
        final events = snapshot.data!;
        if (events.isEmpty) return const Center(child: Text('Todavía no hay eventos públicos.'));
        return ListView.separated(padding: const EdgeInsets.all(24), itemCount: events.length, separatorBuilder: (_, index) => const SizedBox(height: 12), itemBuilder: (context, index) => Card(child: ListTile(leading: const Icon(Icons.event_outlined), title: Text(events[index].title), subtitle: Text('${events[index].startAt.day}/${events[index].startAt.month}/${events[index].startAt.year} · ${events[index].location ?? 'Sin ubicación'}\n${events[index].description}'), isThreeLine: true)));
      }));
}