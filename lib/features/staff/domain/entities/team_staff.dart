class TeamStaff {
  const TeamStaff({required this.id, required this.name, required this.role, required this.isActive});

  final String id;
  final String name;
  final String role;
  final bool isActive;

  factory TeamStaff.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? const {};
    return TeamStaff(
      id: json['id'] as String,
      name: '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
