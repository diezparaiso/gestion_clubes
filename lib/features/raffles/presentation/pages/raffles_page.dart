import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/raffle_repository.dart';
import '../../domain/entities/raffle.dart';

final rafflesProvider = FutureProvider<List<Raffle>>((ref) {
  final clubId = ref.watch(authControllerProvider).clubId;
  if (clubId == null) return Future.value(const []);
  return ref.watch(raffleRepositoryProvider).listRaffles(clubId);
});

class RafflesPage extends ConsumerWidget {
  const RafflesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raffles = ref.watch(rafflesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rifas')),
      body: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('Rifas del club', style: Theme.of(context).textTheme.headlineMedium)), FilledButton.icon(onPressed: () => _showCreateDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Nueva rifa'))]),
        const SizedBox(height: 8),
        const Text('Gestiona campañas y participaciones en modo simulado.'),
        const SizedBox(height: 24),
        Expanded(child: raffles.when(loading: () => const Center(child: CircularProgressIndicator()), error: (error, stack) => const Center(child: Text('No se han podido cargar las rifas.')), data: (items) => items.isEmpty ? const Center(child: Text('Todavía no hay rifas creadas.')) : ListView.separated(itemCount: items.length, separatorBuilder: (_, index) => const SizedBox(height: 12), itemBuilder: (context, index) => _RaffleCard(raffle: items[index])))),
      ])),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => const _CreateRaffleDialog());
    if (saved == true) ref.invalidate(rafflesProvider);
  }
}

class _RaffleCard extends StatelessWidget {
  const _RaffleCard({required this.raffle});
  final Raffle raffle;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(onTap: () => context.pushNamed('raffle-detail', pathParameters: {'raffleId': raffle.id}, extra: raffle), contentPadding: const EdgeInsets.all(16), leading: const CircleAvatar(backgroundColor: Color(0xFFF7EBDD), child: Icon(Icons.confirmation_number_outlined, color: Color(0xFFD27A2C))), title: Text(raffle.title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${raffle.totalNumbers} números · ${raffle.ticketPrice.toStringAsFixed(2).replaceAll('.', ',')} € · termina ${raffle.endAt.day}/${raffle.endAt.month}/${raffle.endAt.year}'), trailing: Chip(label: Text(_statusLabel(raffle.status)), backgroundColor: const Color(0xFFE8EFEC), side: BorderSide.none)));

  static String _statusLabel(RaffleStatus status) => switch (status) { RaffleStatus.draft => 'Borrador', RaffleStatus.scheduled => 'Programada', RaffleStatus.active => 'Activa', RaffleStatus.soldOut => 'Agotada', RaffleStatus.closed => 'Cerrada', RaffleStatus.drawn => 'Sorteada', RaffleStatus.cancelled => 'Cancelada' };
}

class _CreateRaffleDialog extends ConsumerStatefulWidget {
  const _CreateRaffleDialog();
  @override
  ConsumerState<_CreateRaffleDialog> createState() => _CreateRaffleDialogState();
}

class _CreateRaffleDialogState extends ConsumerState<_CreateRaffleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _numbersController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() { _titleController.dispose(); _priceController.dispose(); _numbersController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(raffleRepositoryProvider).createRaffle(clubId: clubId, title: _titleController.text, ticketPrice: double.parse(_priceController.text.replaceAll(',', '.')), totalNumbers: int.parse(_numbersController.text), endAt: DateTime.now().add(const Duration(days: 30)));
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) { setState(() { _saving = false; _error = error.message; }); }
    catch (_) { setState(() { _saving = false; _error = 'No se ha podido guardar la rifa.'; }); }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Nueva rifa'), content: SizedBox(width: 420, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null), const SizedBox(height: 12), TextFormField(controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Precio por número', suffixText: '€'), validator: (value) => double.tryParse((value ?? '').replaceAll(',', '.')) == null ? 'Introduce un precio válido' : null), const SizedBox(height: 12), TextFormField(controller: _numbersController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total de números'), validator: (value) => int.tryParse(value ?? '') == null ? 'Introduce una cantidad válida' : null), if (_error != null) ...[const SizedBox(height: 16), Align(alignment: Alignment.centerLeft, child: Text(_error!, style: const TextStyle(color: Colors.red)))]])))), actions: [TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')), FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'))]);
}
