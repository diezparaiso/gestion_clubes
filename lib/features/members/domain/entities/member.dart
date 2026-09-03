enum MemberStatus { active, pending, expired, cancelled, suspended }

class Member {
  const Member({required this.id, required this.memberNumber, required this.name, required this.email, required this.status});

  final String id;
  final int memberNumber;
  final String name;
  final String email;
  final MemberStatus status;

  factory Member.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? const {};
    final firstName = profile['first_name'] as String? ?? '';
    final lastName = profile['last_name'] as String? ?? '';
    return Member(
      id: json['id'] as String,
      memberNumber: json['member_number'] as int,
      name: '$firstName $lastName'.trim(),
      email: profile['email'] as String? ?? '',
      status: MemberStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => MemberStatus.pending,
      ),
    );
  }
}
