// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): La temporada conserva también start_date para no sobrescribirla al editar.
class Season {
  const Season({required this.id, required this.name, this.startDate});

  final String id;
  final String name;
  final DateTime? startDate;

  factory Season.fromJson(Map<String, dynamic> json) {
    final rawStartDate = json['start_date'];
    return Season(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: rawStartDate == null ? null : DateTime.tryParse(rawStartDate.toString()),
    );
  }
}
