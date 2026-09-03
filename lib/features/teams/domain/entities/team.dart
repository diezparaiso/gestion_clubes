class Team {
  const Team({required this.id, required this.name, required this.category, required this.seasonName, required this.isActive});

  final String id;
  final String name;
  final String category;
  final String seasonName;
  final bool isActive;

  factory Team.fromJson(Map<String, dynamic> json) {
    final season = json['seasons'] as Map<String, dynamic>? ?? const {};
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      seasonName: season['name'] as String? ?? 'Sin temporada',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
