// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Modelo completo de datos de socio según memberships.
enum MemberStatus { active, pending, expired, cancelled, deceased, suspended }

enum MembershipType { standard, youth, family, supporter, other }

class Member {
  const Member({
    required this.id,
    required this.memberNumber,
    required this.name,
    required this.email,
    required this.status,
    required this.membershipType,
    required this.joinDate,
    this.renewalDate,
    this.leaveDate,
    this.notes,
  });

  final String id;
  final int memberNumber;
  final String name;
  final String email;
  final MemberStatus status;
  final MembershipType membershipType;
  final DateTime joinDate;
  final DateTime? renewalDate;
  final DateTime? leaveDate;
  final String? notes;

  factory Member.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? const {};
    final firstName = profile['first_name'] as String? ?? '';
    final lastName = profile['last_name'] as String? ?? '';
    final rawJoinDate = json['join_date']?.toString();
    return Member(
      id: json['id'] as String,
      memberNumber: json['member_number'] as int,
      name: '$firstName $lastName'.trim(),
      email: profile['email'] as String? ?? '',
      status: MemberStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => MemberStatus.pending,
      ),
      membershipType: MembershipType.values.firstWhere(
        (value) => value.name == json['membership_type'],
        orElse: () => MembershipType.standard,
      ),
      joinDate: DateTime.tryParse(rawJoinDate ?? '') ?? DateTime.now(),
      renewalDate: DateTime.tryParse(json['renewal_date']?.toString() ?? ''),
      leaveDate: DateTime.tryParse(json['leave_date']?.toString() ?? ''),
      notes: json['notes'] as String?,
    );
  }
}
