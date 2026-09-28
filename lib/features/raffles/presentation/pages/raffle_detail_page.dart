// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): cierra la gestión de rifas mensuales y respeta raffles_manage en acciones.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): cierre UX del detalle; responsive, refresco y validación de ganador.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../dashboard/presentation/widgets/club_navigation_app_bar.dart';
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
  Future<List<MonthlyRaffleResult>>? _monthlyResults;
  String? _ticketsRaffleId;
  RaffleDraw? _draw;
  bool _drawing = false;
  bool _monthlySaving = false;

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
          final canManage = ClubRolePermissions.has(ref.watch(authControllerProvider).role, 'raffles_manage');
          if (_ticketsRaffleId != raffle.id) {
            _ticketsRaffleId = raffle.id;
            final repository = ref.read(raffleRepositoryProvider);
            _tickets = repository.listTickets(raffle.id);
            if (raffle.type == RaffleType.mensual) {
              _monthlyResults = repository.listMonthlyResults(raffle.id);
            }
          }
          return Scaffold(
        appBar: ClubNavigationAppBar(title: raffle.title),
        body: FutureBuilder<List<RaffleTicket>>(
          future: _tickets!,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return const Center(child: Text('No se han podido cargar las participaciones.'));
            final tickets = snapshot.data!;
            return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [Text('Participaciones', style: Theme.of(context).textTheme.headlineMedium), if (canManage) FilledButton.icon(onPressed: _drawing || _draw != null || raffle.winningNumber != null ? null : () => raffle.type == RaffleType.cesta ? _setBasketWinner(raffle, tickets) : _confirmDraw(tickets), icon: Icon(raffle.type == RaffleType.cesta ? Icons.emoji_events_outlined : Icons.casino_outlined), label: Text(raffle.type == RaffleType.cesta ? 'Elegir ganador' : 'Sortear'))]),
              const SizedBox(height: 8),
              Text('${tickets.length} participaciones registradas. Solo las confirmadas participan en el sorteo.'),
              const SizedBox(height: 8),
              if (raffle.type == RaffleType.mensual)
                _monthlySection(raffle, canManage)
              else ...[
                Text(raffle.type == RaffleType.cesta ? 'Tipo Cesta: el presidente elige el número ganador al finalizar la rifa.' : 'Sorteo puro: el sistema selecciona el ganador con aleatoriedad criptográfica.'),
                if (raffle.winningNumber != null && _draw == null) ...[
                  const SizedBox(height: 20),
                  _DrawResult(draw: RaffleDraw(id: 'stored', raffleId: raffle.id, winningNumber: raffle.winningNumber!, drawnAt: raffle.endAt, method: raffle.type == RaffleType.cesta ? 'president_selected' : 'cryptographic_random')),
                ],
                if (_draw != null) ...[const SizedBox(height: 20), _DrawResult(draw: _draw!)],
                const SizedBox(height: 20),
                if (tickets.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Todavía no hay participaciones.')))
                else
                  ...tickets.map((ticket) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(ticket.number.toString().padLeft(2, '0'))),
                      title: Text(ticket.buyerName),
                      subtitle: Text('${ticket.buyerEmail} · ${_statusLabel(ticket.paymentStatus)}'),
                      trailing: ticket.paymentStatus == 'paid'
                          ? const Icon(Icons.verified_outlined, color: Colors.green)
                          : const Icon(Icons.schedule_outlined),
                    ),
                  )),
              ]
            ]);
          },
        ),
      );
        },
      );

  Widget _monthlySection(Raffle raffle, bool canManage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Rifa mensual: renovación prevista el día ${raffle.monthlyDay ?? '-'}. La activación y renovación real dependen del proveedor de pagos.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Histórico mensual',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (canManage) FilledButton.icon(
              onPressed: _monthlySaving ? null : () => _registerMonthlyResult(raffle),
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('Registrar resultado'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<MonthlyRaffleResult>>(
          future: _monthlyResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No se ha podido cargar el histórico mensual.'),
                ),
              );
            }
            final results = snapshot.data ?? const <MonthlyRaffleResult>[];
            if (results.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Todavía no hay resultados mensuales registrados.'),
                ),
              );
            }
            return Column(
              children: results.map((result) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.emoji_events_outlined)),
                  title: Text('${_monthLabel(result.drawMonth)} · número ${result.winningNumber}'),
                  subtitle: Text(
                    'Premio: ${result.prizeAmount.toStringAsFixed(2).replaceAll('.', ',')} €${result.winnerName == null || result.winnerName!.isEmpty ? '' : ' · Ganador: ${result.winnerName!}'}${result.notes == null || result.notes!.isEmpty ? '' : ' · ${result.notes!}'}',
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _registerMonthlyResult(Raffle raffle) async {
    final data = await showDialog<_MonthlyResultData>(
      context: context,
      builder: (_) => const _MonthlyResultDialog(),
    );
    if (data == null || !mounted) return;
    setState(() => _monthlySaving = true);
    try {
      await ref.read(raffleRepositoryProvider).registerMonthlyResult(
        raffleId: raffle.id,
        month: data.month,
        winningNumber: data.winningNumber,
        prizeAmount: data.prizeAmount,
        notes: data.notes,
      );
      if (!mounted) return;
      setState(() {
        _monthlySaving = false;
        _monthlyResults = ref.read(raffleRepositoryProvider).listMonthlyResults(raffle.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resultado mensual registrado.')));
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() => _monthlySaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _monthlySaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se ha podido registrar el resultado.')));
    }
  }

  static String _monthLabel(DateTime date) {
    const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _setBasketWinner(Raffle raffle, List<RaffleTicket> tickets) async {
    if (DateTime.now().isBefore(raffle.endAt)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La rifa todavía no ha terminado.')));
      return;
    }
    final confirmed = tickets.where((ticket) => ticket.paymentStatus == 'paid').toList()..sort((a, b) => a.number.compareTo(b.number));
    if (confirmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Necesitas al menos una participación confirmada.')));
      return;
    }
    final numberController = TextEditingController();
    final number = await showDialog<int>(context: context, builder: (context) => AlertDialog(
      title: const Text('Número agraciado'),
      content: TextField(controller: numberController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Número participante', hintText: 'Entre 1 y ${raffle.totalNumbers}')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () { final n = int.tryParse(numberController.text); if (n != null && n >= 1 && n <= raffle.totalNumbers && confirmed.any((ticket) => ticket.number == n)) Navigator.pop(context, n); }, child: const Text('Confirmar')),
      ],
    ));
    numberController.dispose();
    if (number == null || !mounted) return;
    setState(() => _drawing = true);
    try {
      final draw = await ref.read(raffleRepositoryProvider).setBasketWinner(raffleId: raffle.id, winningNumber: number);
      if (mounted) setState(() { _draw = draw; _drawing = false; });
    } on PostgrestException catch (e) {
      if (mounted) { setState(() => _drawing = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    } catch (_) {
      if (mounted) { setState(() => _drawing = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se ha podido registrar el ganador.'))); }
    }
  }

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

class _MonthlyResultData {
  const _MonthlyResultData({
    required this.month,
    required this.winningNumber,
    required this.prizeAmount,
    this.notes,
  });

  final DateTime month;
  final int winningNumber;
  final double prizeAmount;
  final String? notes;
}

class _MonthlyResultDialog extends StatefulWidget {
  const _MonthlyResultDialog();

  @override
  State<_MonthlyResultDialog> createState() => _MonthlyResultDialogState();
}

class _MonthlyResultDialogState extends State<_MonthlyResultDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _prizeController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void dispose() {
    _numberController.dispose();
    _prizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Resultado mensual'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Mes del resultado'),
              subtitle: Text('${_month.month}/${_month.year}'),
              trailing: TextButton(onPressed: _pickMonth, child: const Text('Cambiar')),
            ),
            TextFormField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Número ganador'),
              validator: (value) => int.tryParse(value ?? '') == null ? 'Introduce un número válido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prizeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Premio', suffixText: '€'),
              validator: (value) => double.tryParse((value ?? '').replaceAll(',', '.')) == null ? 'Introduce un importe válido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Observaciones (opcional)'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _MonthlyResultData(
              month: _month,
              winningNumber: int.parse(_numberController.text),
              prizeAmount: double.parse(_prizeController.text.replaceAll(',', '.')),
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            ),
          );
        },
        child: const Text('Guardar'),
      ),
    ],
  );

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2024),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) setState(() => _month = DateTime(picked.year, picked.month, 1));
  }
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