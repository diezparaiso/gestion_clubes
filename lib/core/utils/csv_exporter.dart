String escapeCsvValue(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

String transactionsToCsv(Iterable<({String date, String type, String category, String description, double amount})> transactions) {
  final rows = <String>['Fecha;Tipo;Categoría;Descripción;Importe'];
  for (final transaction in transactions) {
    rows.add([
      transaction.date,
      transaction.type,
      transaction.category,
      transaction.description,
      transaction.amount.toStringAsFixed(2).replaceAll('.', ','),
    ].map(escapeCsvValue).join(';'));
  }
  return rows.join('\n');
}
