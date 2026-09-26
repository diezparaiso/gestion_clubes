// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): área del socio para consultar rifas, suscripciones y recibos.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../dashboard/presentation/widgets/club_navigation_app_bar.dart';
import '../../data/repositories/raffle_repository.dart';

class MyRafflesPage extends ConsumerWidget {
  const MyRafflesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseService.isConfigured) {
      return const Scaffold(body: Center(child: Text('El área de rifas del socio estará disponible al conectar Supabase y el sistema de pagos.')));
    }
    final profileId = Supabase.instance.client.auth.currentUser?.id;
    if (profileId == null) {
      return const Scaffold(body: Center(child: Text('Inicia sesión para consultar tus rifas.')));
    }

    final data = Future.wait([
      ref.read(raffleRepositoryProvider).listMyMonthlySubscriptions(profileId),
      ref.read(raffleRepositoryProvider).listMyPaidTickets(profileId),
    ]);

    return Scaffold(
      appBar: const ClubNavigationAppBar(title: 'Mis rifas'),
      body: FutureBuilder<List<dynamic>>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('No se ha podido cargar tu información de rifas.'));
          }

          final subscriptions = (snapshot.data?[0] as List<Map<String, dynamic>>?) ?? const [];
          final tickets = (snapshot.data?[1] as List<Map<String, dynamic>>?) ?? const [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text('Mis rifas', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text('Suscripciones mensuales', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (subscriptions.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No tienes suscripciones mensuales activas.')))
              else
                ...subscriptions.map((item) => _subscriptionCard(context, item)),
              const SizedBox(height: 24),
              Text('Participaciones y recibos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (tickets.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Todavía no hay pagos de rifas asociados a tu cuenta.')))
              else
                ...tickets.map((ticket) => _ticketCard(context, ticket)),
            ],
          );
        },
      ),
    );
  }

  Widget _subscriptionCard(BuildContext context, Map<String, dynamic> item) {
    final raffle = (item['raffles'] as Map<String, dynamic>?) ?? const {};
    final status = item['status'] as String? ?? 'active';
    final periodEnd = item['current_period_end'] as String?;
    final periodText = periodEnd == null ? '' : ' · Próximo periodo: ' + _formatDate(periodEnd);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.autorenew_outlined)),
        title: Text(raffle['title'] as String? ?? 'Rifa mensual'),
        subtitle: Text(
          'Número ' + item['number'].toString() + ' · ' +
          item['amount'].toString() + ' ' + (item['currency'] ?? 'eur').toString() + periodText,
        ),
        trailing: Chip(label: Text(_subscriptionStatus(status))),
      ),
    );
  }

  Widget _ticketCard(BuildContext context, Map<String, dynamic> ticket) {
    final raffle = (ticket['raffles'] as Map<String, dynamic>?) ?? const {};
    final receipt = ticket['receipt_number'] as String?;
    final reference = ticket['payment_reference'] as String?;
    final subtitle = (receipt == null ? 'Pago confirmado' : 'Recibo ' + receipt) +
        (reference == null ? '' : ' · Ref. ' + reference);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.confirmation_number_outlined)),
        title: Text((raffle['title'] as String? ?? 'Rifa') + ' · número ' + ticket['number'].toString()),
        subtitle: Text(subtitle),
        trailing: receipt == null
            ? null
            : IconButton(
                tooltip: 'Ver recibo',
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: () => _showReceipt(context, ticket, raffle),
              ),
      ),
    );
  }

  Future<void> _showReceipt(
    BuildContext context,
    Map<String, dynamic> ticket,
    Map<String, dynamic> raffle,
  ) async {
    final receipt = ticket['receipt_number'] as String? ?? 'Pendiente';
    final reference = ticket['payment_reference'] as String? ?? '—';
    final paidAt = ticket['paid_at'] as String? ?? '—';
    final price = (raffle['ticket_price'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final text = 'RECIBO DE PARTICIPACIÓN\n'
        + 'Rifa: ' + (raffle['title'] as String? ?? 'Rifa') + '\n'
        + 'Número: ' + ticket['number'].toString() + '\n'
        + 'Importe: ' + price + ' €\n'
        + 'Recibo: ' + receipt + '\n'
        + 'Referencia de pago: ' + reference + '\n'
        + 'Fecha de pago: ' + paidAt;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Comprobante de participación'),
        content: SelectableText(text),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comprobante copiado.')),
                );
              }
            },
            child: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static String _subscriptionStatus(String status) => switch (status) {
        'active' => 'Activa',
        'paused' => 'Pausada',
        'cancelled' => 'Cancelada',
        'past_due' => 'Pago pendiente',
        _ => status,
      };

  static String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return date.day.toString() + '/' + date.month.toString() + '/' + date.year.toString();
  }
}
