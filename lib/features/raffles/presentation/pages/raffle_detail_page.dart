import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/raffle_repository.dart';
import '../../domain/entities/raffle.dart';

class RaffleDetailPage extends ConsumerStatefulWidget {
  const RaffleDetailPage({super.key, this.raffle, required this.raffleId, required this.clubId});

  final Raffle? raffle;
  final String raffleId;
  final String? clubId;

  @override
  ConsumerState<RaffleDetailPage> createState() => _RaffleDetailPageState();
}

class _RaffleDetailPageState extends ConsumerState<RaffleDetailPage> {
  late Future<Raffle> _raffle;
  Future<List<RaffleTicket>>? _tickets;
  String? _ticketsRaffleId;
  RaffleDraw? _draw;
  bool _drawing = false;

  @override
  void initState() {
    super.initState();
    final repository = ref.read(raffleRepositoryProvider);
    _raffle = widget.raffle != null
        ? Future.value(widget.raffle)
        : widget.clubId == null
            ? Future.error(const AuthException('La sesión ha expirado.'))
            : repository.getRaffle(clubId: widget.clubId!, raffleId: widget.raffleId);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Raffle>(
        future: _raffle,
        builder: (context, raffleSnapshot) {
          if (raffleSnapshot.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (raffleSnapshot.hasError || raffleSnapshot.data == null) return const MissingRafflePage();
          final raffle = raffleSnapshot.data!;
          if (_ticketsRaffleId != raffle.id) {
            _ticketsRaffleId = raffle.id;
            _tickets = ref.read(raffleRepositoryProvider).listTickets(raffle.id);
          }
          return Scaffold(
        appBar: AppBar(title: Text(raffle.title)),
        body: FutureBuilder<List<RaffleTicket>>(
          future: _tickets!,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return const Center(child: Text('No se han podido cargar las participaciones.'));
            final tickets = snapshot.data!;
            return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              Row(children: [Expanded(child: Text('Participaciones', style: Theme.of(context).textTheme.headlineMedium)), FilledButton.icon(onPressed: _drawing || _draw != null ? null : () => _confirmDraw(tickets), icon: const Icon(Icons.casino_outlined), label: const Text('Sortear'))]),
              const SizedBox(height: 8),
              Text('${tickets.length} participaciones registradas. Solo las confirmadas participan en el sorteo.'),
              if (_draw != null) ...[const SizedBox(height: 20), _DrawResult(draw: _draw!)],
              const SizedBox(height: 20),
              if (tickets.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Todavía no hay participaciones.')))
              else ...tickets.map((ticket) => Card(child: ListTile(leading: CircleAvatar(child: Text(ticket.number.toString().padLeft(2, '0'))), title: Text(ticket.buyerName), subtitle: Text('${ticket.buyerEmail} · ${_statusLabel(ticket.paymentStatus)}'), trailing: ticket.paymentStatus == 'paid' ? const Icon(Icons.verified_outlined, color: Colors.green) : const Icon(Icons.schedule_outlined))))
            ]);
          },
        ),
      );
        },
      );

  Future<void> _confirmDraw(List<RaffleTicket> tickets) async {
    if (tickets.every((ticket) => ticket.paymentStatus != 'paid')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Necesitas al menos una participación confirmada.')));
      return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Confirmar sorteo'), content: const Text('El resultado quedará registrado y no podrá repetirse desde esta pantalla.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sortear'))]));
    if (confirmed != true || !mounted) return;
    setState(() => _drawing = true);
    try {
      final draw = await ref.read(raffleRepositoryProvider).drawRaffle(raffleId: widget.raffle?.id ?? widget.raffleId);
      if (mounted) setState(() { _draw = draw; _drawing = false; });
    } on PostgrestException catch (error) {
      if (mounted) { setState(() => _drawing = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message))); }
    } catch (_) {
      if (mounted) { setState(() => _drawing = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se ha podido realizar el sorteo.'))); }
    }
  }

  static String _statusLabel(String status) => switch (status) { 'paid' => 'Confirmada', 'pending' => 'Pendiente', 'cancelled' => 'Cancelada', _ => status };
}

class _DrawResult extends StatelessWidget {
  const _DrawResult({required this.draw});
  final RaffleDraw draw;

  @override
  Widget build(BuildContext context) => Card(color: Theme.of(context).colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [const Icon(Icons.emoji_events_outlined, size: 36), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Número ganador: ${draw.winningNumber.toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.titleLarge), Text('Sorteo registrado el ${draw.drawnAt.day}/${draw.drawnAt.month}/${draw.drawnAt.year}')]))])));
}

class MissingRafflePage extends StatelessWidget {
  const MissingRafflePage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Abre la rifa desde el listado del club.')));
}