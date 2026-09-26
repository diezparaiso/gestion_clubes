class Player {
  const Player({
    required this.id,
    required this.name,
    required this.jerseyNumber,
    required this.isActive,
    required this.phone,
    required this.guardianName,
    required this.guardianPhone,
    required this.guardianEmail,
    required this.guardianRelationship,
  });

  final String id;
  final String name;
  final int? jerseyNumber;
  final bool isActive;
  final String? phone;
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianEmail;
  final String? guardianRelationship;

  factory Player.fromJson(Map<String, dynamic> json) {
    final player = json['players'] as Map<String, dynamic>? ?? const {};
    final profile = player['profiles'] as Map<String, dynamic>? ?? const {};
    return Player(
      id: json['id'] as String,
      name: '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
      jerseyNumber: json['jersey_number'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      phone: player['phone'] as String?,
      guardianName: player['guardian_name'] as String?,
      guardianPhone: player['guardian_phone'] as String?,
      guardianEmail: player['guardian_email'] as String?,
      guardianRelationship: player['guardian_relationship'] as String?,
    );
  }
}
