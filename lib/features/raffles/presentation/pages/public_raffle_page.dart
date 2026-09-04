import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/raffle_repository.dart';
import '../../domain/entities/raffle.dart';

class PublicRafflePage extends StatefulWidget {
  const PublicRafflePage({super.key, required this.clubSlug, required this.raffleSlug});

  final String clubSlug;
  final String raffleSlug;

  @override
  State<PublicRafflePage> createState() => _PublicRafflePageState();
}

class _PublicRafflePageState extends State<PublicRafflePage> {
  late final Future<Raffle> _raffle;
  final Set<int> _selectedNumbers = {};

  @override
  void initState() {
    super.initState();
    _raffle = RaffleRepository().getPublicRaffle(clubSlug: widget.clubSlug, raffleSlug: widget.raffleSlug);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rifa del club')),
        body: FutureBuilder<Raffle>(
          future: _raffle,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return const Center(child: Text('Esta rifa no está disponible.'));
            return _content(context, snapshot.data!);
          },
        ),
      );

  Widget _content(BuildContext context, Raffle raffle) {
    final shareUrl = Uri.base.replace(path: '/r/${widget.clubSlug}/${widget.raffleSlug}').toString();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Text(raffle.clubName ?? widget.clubSlug, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(raffle.title, style: Theme.of(context).textTheme.headlineMedium),
          if (raffle.description != null) ...[const SizedBox(height: 8), Text(raffle.description!)],
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${raffle.ticketPrice.toStringAsFixed(2).replaceAll('.', ',')} € por número', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${raffle.totalNumbers - raffle.occupiedNumbers.length} disponibles de ${raffle.totalNumbers}'),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: List.generate(raffle.totalNumbers, (index) => _numberTile(raffle, index))),
          ]))),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _selectedNumbers.isEmpty ? null : () => _showSimulationMessage(context), icon: const Icon(Icons.confirmation_number_outlined), label: Text(_selectedNumbers.isEmpty ? 'Selecciona números' : 'Reservar ${_selectedNumbers.length} número(s)')),
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [QrImageView(data: shareUrl, size: 120), const SizedBox(width: 20), const Expanded(child: Text('Comparte esta rifa escaneando el código QR. Los pagos reales están desactivados por ahora.'))]))),
        ]),
      ),
    );
  }

  Widget _numberTile(Raffle raffle, int number) {
    final isOccupied = raffle.occupiedNumbers.contains(number);
    final isSelected = _selectedNumbers.contains(number);
    return SizedBox(width: 48, height: 42, child: OutlinedButton(onPressed: isOccupied ? null : () => setState(() => isSelected ? _selectedNumbers.remove(number) : _selectedNumbers.add(number)), style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null), child: Text(number.toString().padLeft(2, '0'))));
  }

  void _showSimulationMessage(BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva simulada. El pago real todavía no está disponible.')));
}