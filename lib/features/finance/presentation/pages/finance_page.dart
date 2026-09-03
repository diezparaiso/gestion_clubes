import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/auth_controller.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/utils/csv_exporter.dart';
import '../../data/repositories/finance_repository.dart';
import '../../domain/entities/financial_transaction.dart';

final transactionsProvider = FutureProvider<List<FinancialTransaction>>((ref) {
  final clubId = ref.watch(authControllerProvider).clubId;
  if (clubId == null) return Future.value(const []);
  return ref.watch(financeRepositoryProvider).listTransactions(clubId);
});

class FinancePage extends ConsumerWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tesorería')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(transactionsProvider.future),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Control financiero', style: Theme.of(context).textTheme.headlineMedium)),
              IconButton(onPressed: () => _exportTransactions(context, ref), tooltip: 'Exportar CSV', icon: const Icon(Icons.download_outlined)),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: () => _showTransactionDialog(context, ref), icon: const Icon(Icons.add_chart_outlined), label: const Text('Nuevo movimiento')),
            ]),
            const SizedBox(height: 8),
            const Text('Registra ingresos y gastos y consulta el saldo del club.'),
            const SizedBox(height: 24),
            Expanded(child: transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Center(child: Text('No se han podido cargar los movimientos.')),
              data: (items) => _FinanceContent(transactions: items),
            )),
          ]),
        ),
      ),
    );
  }

  Future<void> _showTransactionDialog(BuildContext context, WidgetRef ref) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => const _TransactionDialog());
    if (saved == true) ref.invalidate(transactionsProvider);
  }

  Future<void> _exportTransactions(BuildContext context, WidgetRef ref) async {
    try {
      final transactions = await ref.read(transactionsProvider.future);
      final csv = transactionsToCsv(transactions.map((transaction) => (
        date: '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}',
        type: transaction.type == TransactionType.income ? 'Ingreso' : 'Gasto',
        category: transaction.category,
        description: transaction.description,
        amount: transaction.amount,
      )));
      await downloadCsv(filename: 'movimientos_financieros.csv', content: csv);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV generado correctamente.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se ha podido exportar el CSV.')));
    }
  }
}

class _FinanceContent extends StatelessWidget {
  const _FinanceContent({required this.transactions});

  final List<FinancialTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final income = transactions.where((item) => item.type == TransactionType.income).fold<double>(0, (sum, item) => sum + item.amount);
    final expense = transactions.where((item) => item.type == TransactionType.expense).fold<double>(0, (sum, item) => sum + item.amount);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 16, runSpacing: 16, children: [
        _FinanceMetric(label: 'Saldo', value: _formatCurrency(8450 + income - expense), color: const Color(0xFF168B68)),
        _FinanceMetric(label: 'Ingresos', value: _formatCurrency(income), color: const Color(0xFF3276B1)),
        _FinanceMetric(label: 'Gastos', value: _formatCurrency(expense), color: const Color(0xFFD27A2C)),
      ]),
      const SizedBox(height: 28),
      Text('Movimientos recientes', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Expanded(child: Card(child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: transactions.length,
        separatorBuilder: (_, index) => const Divider(height: 1),
        itemBuilder: (context, index) => _TransactionTile(transaction: transactions[index]),
      ))),
    ]);
  }

  static String _formatCurrency(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
}

class _FinanceMetric extends StatelessWidget {
  const _FinanceMetric({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final FinancialTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    return ListTile(leading: CircleAvatar(backgroundColor: isIncome ? const Color(0xFFE8EFEC) : const Color(0xFFF7EBDD), child: Icon(isIncome ? Icons.south_west_rounded : Icons.north_east_rounded, color: isIncome ? const Color(0xFF168B68) : const Color(0xFFD27A2C))), title: Text(transaction.description, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${transaction.category} · ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'), trailing: Text('${isIncome ? '+' : '-'}${_FinanceContent._formatCurrency(transaction.amount)}', style: TextStyle(color: isIncome ? const Color(0xFF168B68) : const Color(0xFFD27A2C), fontWeight: FontWeight.w800)));
  }
}

class _TransactionDialog extends ConsumerStatefulWidget {
  const _TransactionDialog();

  @override
  ConsumerState<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends ConsumerState<_TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  TransactionType _type = TransactionType.income;
  String _category = 'other';
  bool _saving = false;
  String? _error;

  @override
  void dispose() { _amountController.dispose(); _descriptionController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(financeRepositoryProvider).createTransaction(clubId: clubId, type: _type, category: _category, amount: double.parse(_amountController.text.replaceAll(',', '.')), description: _descriptionController.text);
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) { setState(() { _saving = false; _error = error.message; }); }
    catch (_) { setState(() { _saving = false; _error = 'No se ha podido guardar el movimiento.'; }); }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo movimiento'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TransactionType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: TransactionType.income, child: Text('Ingreso')),
                    DropdownMenuItem(value: TransactionType.expense, child: Text('Gasto')),
                  ],
                  onChanged: (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Importe', suffixText: '€'),
                  validator: (value) => double.tryParse((value ?? '').replaceAll(',', '.')) == null ? 'Introduce un importe válido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: const [
                    DropdownMenuItem(value: 'membership', child: Text('Cuotas')),
                    DropdownMenuItem(value: 'sponsorship', child: Text('Patrocinio')),
                    DropdownMenuItem(value: 'raffle', child: Text('Rifa')),
                    DropdownMenuItem(value: 'event', child: Text('Evento')),
                    DropdownMenuItem(value: 'equipment', child: Text('Equipamiento')),
                    DropdownMenuItem(value: 'federation', child: Text('Federación')),
                    DropdownMenuItem(value: 'facilities', child: Text('Instalaciones')),
                    DropdownMenuItem(value: 'salaries', child: Text('Salarios')),
                    DropdownMenuItem(value: 'supplies', child: Text('Suministros')),
                    DropdownMenuItem(value: 'other', child: Text('Otros')),
                  ],
                  onChanged: (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerLeft, child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar')),
      ],
    );
  }
}
