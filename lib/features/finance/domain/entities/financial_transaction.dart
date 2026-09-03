enum TransactionType { income, expense }

class FinancialTransaction {
  const FinancialTransaction({required this.id, required this.type, required this.category, required this.amount, required this.description, required this.date});

  final String id;
  final TransactionType type;
  final String category;
  final double amount;
  final String description;
  final DateTime date;

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] as String,
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      date: DateTime.parse(json['transaction_date'] as String),
    );
  }
}
