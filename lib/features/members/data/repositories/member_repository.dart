// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Valida coherencia de socios y fechas antes de persistir.
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
        .select('id, member_number, membership_type, status, join_date, renewal_date, leave_date, notes, address, postal_code, city, province, country, profiles!inner(first_name, last_name, email)')
        .eq('club_id', clubId)
        .order('member_number');
    return rows.map(Member.fromJson).toList();
  }

  Future<Member> createMember({required String clubId, required int memberNumber, required String firstName, required String lastName, required String email, String? address, String? postalCode, String? city, String? province, String? country}) async {
    if (clubId.trim().isEmpty) throw const FormatException('No hay un club activo.');
    if (memberNumber <= 0) throw const FormatException('El número de socio debe ser mayor que 0.');
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) throw const FormatException('El email no es válido.');
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) throw const FormatException('Nombre y apellidos son obligatorios.');
    if (!SupabaseService.isConfigured) {
      return Member(id: 'member-$memberNumber', memberNumber: memberNumber, name: '$firstName $lastName', email: email, status: MemberStatus.active, membershipType: MembershipType.standard, joinDate: DateTime.now());
    }

    final client = Supabase.instance.client;
    final profile = await client.from('profiles').select('id').eq('email', normalizedEmail).maybeSingle();
    if (profile == null) throw const PostgrestException(message: 'No existe una cuenta con ese email. La persona debe registrarse antes de añadirla.');

    final row = await client.from('memberships').insert({
      'club_id': clubId,
      'profile_id': profile['id'],
      'member_number': memberNumber,
      'status': 'active',
      'membership_type': 'standard',
      'join_date': DateTime.now().toIso8601String().split('T').first,
      'address': address?.trim().isEmpty == true ? null : address?.trim(),
      'postal_code': postalCode?.trim().isEmpty == true ? null : postalCode?.trim(),
      'city': city?.trim().isEmpty == true ? null : city?.trim(),
      'province': province?.trim().isEmpty == true ? null : province?.trim(),
      'country': country?.trim().isEmpty == true ? 'ES' : country!.trim().toUpperCase(),
    }).select('id, member_number, membership_type, status, join_date, renewal_date, leave_date, notes, address, postal_code, city, province, country, profiles!inner(first_name, last_name, email)').single();
    return Member.fromJson(row);
  }


  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Actualiza campos ya existentes de memberships.
  // No requiere cambios de esquema Supabase.
  Future<Member> updateMember({
    required String clubId,
    required String memberId,
    required int memberNumber,
    required MemberStatus status,
    required MembershipType membershipType,
    required DateTime joinDate,
    DateTime? renewalDate,
    DateTime? leaveDate,
    String? notes,
    String? address,
    String? postalCode,
    String? city,
    String? province,
    String? country,
  }) async {
    if (clubId.trim().isEmpty) throw const FormatException('No hay un club activo.');
    if (memberNumber <= 0) throw const FormatException('El número de socio debe ser mayor que 0.');
    if (renewalDate != null && renewalDate.isBefore(joinDate)) throw const FormatException('La renovación no puede ser anterior al alta.');
    if (leaveDate != null && leaveDate.isBefore(joinDate)) throw const FormatException('La baja no puede ser anterior al alta.');
    if (!SupabaseService.isConfigured) {
      final index = _demoMembers.indexWhere((member) => member.id == memberId);
      if (index < 0) throw StateError('Socio no encontrado.');
      final current = _demoMembers[index];
      final updated = Member(
        id: current.id,
        memberNumber: memberNumber,
        name: current.name,
        email: current.email,
        status: status,
        membershipType: membershipType,
        joinDate: joinDate,
        renewalDate: renewalDate,
        leaveDate: leaveDate,
        notes: notes,
        address: address?.trim().isEmpty == true ? null : address?.trim(),
        postalCode: postalCode?.trim().isEmpty == true ? null : postalCode?.trim(),
        city: city?.trim().isEmpty == true ? null : city?.trim(),
        province: province?.trim().isEmpty == true ? null : province?.trim(),
        country: country?.trim().isEmpty == true ? 'ES' : country!.trim().toUpperCase(),
      );
      _demoMembers[index] = updated;
      return updated;
    }
    final row = await Supabase.instance.client.from('memberships').update({
      'member_number': memberNumber,
      'status': status.name,
      'membership_type': membershipType.name,
      'join_date': joinDate.toIso8601String().split('T').first,
      'renewal_date': renewalDate?.toIso8601String().split('T').first,
      'leave_date': leaveDate?.toIso8601String().split('T').first,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'address': address?.trim().isEmpty == true ? null : address?.trim(),
      'postal_code': postalCode?.trim().isEmpty == true ? null : postalCode?.trim(),
      'city': city?.trim().isEmpty == true ? null : city?.trim(),
      'province': province?.trim().isEmpty == true ? null : province?.trim(),
      'country': country?.trim().isEmpty == true ? 'ES' : country!.trim().toUpperCase(),
    }).eq('id', memberId).eq('club_id', clubId).select('id, member_number, membership_type, status, join_date, renewal_date, leave_date, notes, address, postal_code, city, province, country, profiles!inner(first_name, last_name, email)').single();
    return Member.fromJson(row);
  }

  static final _demoMembers = <Member>[
    Member(id: 'member-100', memberNumber: 100, name: 'Ana García', email: 'ana@ejemplo.com', status: MemberStatus.active, membershipType: MembershipType.standard, joinDate: DateTime(2026, 7, 1)),
    Member(id: 'member-101', memberNumber: 101, name: 'Luis Martín', email: 'luis@ejemplo.com', status: MemberStatus.active, membershipType: MembershipType.family, joinDate: DateTime(2026, 7, 1)),
    Member(id: 'member-103', memberNumber: 103, name: 'Marta López', email: 'marta@ejemplo.com', status: MemberStatus.pending, membershipType: MembershipType.youth, joinDate: DateTime(2026, 9, 1)),
  ];
}
