class ClubMember {
  final String id;
  final String clubId;
  final String profileId;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firstName;
  final String? lastName;
  final String? email;

  const ClubMember({
    required this.id,
    required this.clubId,
    required this.profileId,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.firstName,
    this.lastName,
    this.email,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      profileId: json['profile_id'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'club_id': clubId,
    'profile_id': profileId,
    'role': role,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
  };

  String get displayName => '$firstName $lastName'.trim();

  bool get isPresident => role == 'club_president';
  bool get isTreasurer => role == 'club_treasurer';
  bool get isSecretary => role == 'club_secretary';
  bool get isManager => isPresident || isSecretary;
  bool get isCoach => role == 'coach';
  bool get isStaff => role == 'staff';
  bool get isPlayer => role == 'player';

  ClubMember copyWith({
    String? id,
    String? clubId,
    String? profileId,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return ClubMember(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      profileId: profileId ?? this.profileId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }
}