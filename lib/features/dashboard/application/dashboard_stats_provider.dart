// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): el dashboard consulta solo módulos permitidos por RLS.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_controller.dart';
import '../../../features/finance/data/repositories/finance_repository.dart';
import '../../../features/finance/domain/entities/financial_transaction.dart';
import '../../../features/members/data/repositories/member_repository.dart';
import '../../../features/teams/data/repositories/team_repository.dart';

class DashboardStats {
  const DashboardStats({required this.balance, required this.income, required this.expenses, required this.memberCount, required this.teamCount});

  final double balance;
  final double income;
  final double expenses;
  final int memberCount;
  final int teamCount;
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final clubId = ref.watch(authControllerProvider).clubId;
  if (clubId == null) return const DashboardStats(balance: 0, income: 0, expenses: 0, memberCount: 0, teamCount: 0);

  final financeRepository = ref.watch(financeRepositoryProvider);
  final role = ref.watch(authControllerProvider).role;
  final canMembers = ClubRolePermissions.has(role, 'members_view');
  final canTeams = ClubRolePermissions.has(role, 'teams_view');
  final canFinance = ClubRolePermissions.has(role, 'finance_view');
  final results = await Future.wait([
    canMembers ? ref.watch(memberRepositoryProvider).listMembers(clubId) : Future.value(const []),
    canTeams ? ref.watch(teamRepositoryProvider).listTeams(clubId) : Future.value(const []),
    canFinance ? financeRepository.listTransactions(clubId) : Future.value(const <FinancialTransaction>[]),
    canFinance ? financeRepository.getOpeningBalance(clubId) : Future.value(0),
  ]);
  final transactions = results[2] as List<FinancialTransaction>;
  final income = transactions.where((item) => item.type == TransactionType.income).fold<double>(0, (sum, item) => sum + item.amount);
  final expenses = transactions.where((item) => item.type == TransactionType.expense).fold<double>(0, (sum, item) => sum + item.amount);
  return DashboardStats(balance: canFinance ? (results[3] as double) + income - expenses : 0, income: canFinance ? income : 0, expenses: canFinance ? expenses : 0, memberCount: canMembers ? (results[0] as List).length : 0, teamCount: canTeams ? (results[1] as List).length : 0);
});
