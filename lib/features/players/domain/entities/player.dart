class Player {
  const Player({required this.id, required this.name, required this.jerseyNumber, required this.isActive});

  final String id;
  final String name;
  final int? jerseyNumber;
  final bool isActive;

  factory Player.fromJson(Map<String, dynamic> json) {
    final profile = json['players']?['profiles'] as Map<String, dynamic>? ?? const {};
    return Player(id: json['id'] as String, name: '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(), jerseyNumber: json['jersey_number'] as int?, isActive: json['is_active'] as bool? ?? true);
  }
}
