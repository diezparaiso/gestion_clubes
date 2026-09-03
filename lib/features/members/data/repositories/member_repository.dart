import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/member.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) => MemberRepository());

class MemberRepository {
  Future<List<Member>> listMembers(String clubId) async {
    if (!SupabaseService.isConfigured) return _demoMembers;

    final rows = await Supabase.instance.client
        .from('memberships')
        .select('id, member_number, status, profiles!inner(first_name, last_name, email)')
        .eq('club_id', clubId)
        .order('member_number');
    return rows.map(Member.fromJson).toList();
  }

  Future<Member> createMember({required String clubId, required int memberNumber, required String firstName, required String lastName, required String email}) async {
    if (!SupabaseService.isConfigured) {
      return Member(id: 'member-$memberNumber', memberNumber: memberNumber, name: '$firstName $lastName', email: email, status: MemberStatus.active);
    }

    final client = Supabase.instance.client;
    final profile = await client.from('profiles').select('id').eq('email', email.trim()).maybeSingle();
    if (profile == null) throw const PostgrestException(message: 'No existe una cuenta con ese email. La persona debe registrarse antes de añadirla.');

    final row = await client.from('memberships').insert({
      'club_id': clubId,
      'profile_id': profile['id'],
      'member_number': memberNumber,
      'status': 'active',
      'membership_type': 'standard',
    }).select('id, member_number, status, profiles!inner(first_name, last_name, email)').single();
    return Member.fromJson(row);
  }

  static const _demoMembers = [
    Member(id: 'member-100', memberNumber: 100, name: 'Ana García', email: 'ana@ejemplo.com', status: MemberStatus.active),
    Member(id: 'member-101', memberNumber: 101, name: 'Luis Martín', email: 'luis@ejemplo.com', status: MemberStatus.active),
    Member(id: 'member-103', memberNumber: 103, name: 'Marta López', email: 'marta@ejemplo.com', status: MemberStatus.pending),
  ];
}
