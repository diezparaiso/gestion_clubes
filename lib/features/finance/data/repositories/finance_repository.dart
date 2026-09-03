import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/financial_transaction.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) => FinanceRepository());

class FinanceRepository {
  Future<double> getOpeningBalance(String clubId) async {
    if (!SupabaseService.isConfigured) return 7180;
    final rows = await Supabase.instance.client.from('financial_accounts').select('opening_balance').eq('club_id', clubId).eq('is_active', true);
    return rows.fold<double>(0, (sum, row) => sum + (row['opening_balance'] as num).toDouble());
  }

  Future<List<FinancialTransaction>> listTransactions(String clubId) async {
    if (!SupabaseService.isConfigured) return List.unmodifiable(_demoTransactions);
    final rows = await Supabase.instance.client.from('financial_transactions').select('id, type, category, amount, description, transaction_date').eq('club_id', clubId).order('transaction_date', ascending: false);
    return rows.map(FinancialTransaction.fromJson).toList();
  }

  Future<void> createTransaction({required String clubId, required TransactionType type, required String category, required double amount, required String description}) async {
    if (!SupabaseService.isConfigured) {
      _demoTransactions.insert(0, FinancialTransaction(id: 'transaction-${_demoTransactions.length + 1}', type: type, category: category, amount: amount, description: description, date: DateTime.now()));
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('La sesión ha expirado.');
    await Supabase.instance.client.from('financial_transactions').insert({
      'club_id': clubId,
      'account_id': await _defaultAccountId(clubId),
      'type': type.name,
      'category': category,
      'amount': amount,
      'transaction_date': DateTime.now().toIso8601String().substring(0, 10),
      'description': description.trim(),
      'created_by': userId,
    });
  }

  Future<String> _defaultAccountId(String clubId) async {
    final account = await Supabase.instance.client.from('financial_accounts').select('id').eq('club_id', clubId).eq('is_active', true).limit(1).maybeSingle();
    if (account == null) throw const PostgrestException(message: 'No hay una cuenta financiera activa configurada.');
    return account['id'] as String;
  }

  static final _demoTransactions = <FinancialTransaction>[
    FinancialTransaction(id: 'transaction-1', type: TransactionType.income, category: 'Cuotas', amount: 2450, description: 'Cuotas de socios', date: DateTime(2026, 9, 2)),
    FinancialTransaction(id: 'transaction-2', type: TransactionType.expense, category: 'Material', amount: 350, description: 'Material deportivo', date: DateTime(2026, 9, 1)),
    FinancialTransaction(id: 'transaction-3', type: TransactionType.expense, category: 'Federación', amount: 830, description: 'Licencias federativas', date: DateTime(2026, 8, 28)),
  ];
}
