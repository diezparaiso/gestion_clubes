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
    final profile = json['players']?['profiles'] as Map<String, dynamic>? ?? const {};
    return Player(
      id: json['id'] as String,
      name: '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
      jerseyNumber: json['jersey_number'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      phone: json['phone'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      guardianEmail: json['guardian_email'] as String?,
      guardianRelationship: json['guardian_relationship'] as String?,
    );
  }
}
