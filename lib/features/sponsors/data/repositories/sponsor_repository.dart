// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Refuerza aislamiento por club y validación de altas de patrocinadores.\n// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Evita acceder al cliente de Supabase cuando la app funciona en modo demo.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/public_sponsor.dart';
import '../../domain/entities/sponsor.dart';

class SponsorRepository {
  final SupabaseClient? _supabase;

  SponsorRepository(this._supabase);

  Future<List<Sponsor>> getClubSponsors(String clubId) async {
    if (!SupabaseService.isConfigured || _supabase == null || clubId.trim().isEmpty) {
      return _demoSponsors();
    }

    final supabase = _supabase;
    try {
      final response = await supabase
          .from('sponsors')
          .select()
          .eq('club_id', clubId)
          .order('contract_start_date', ascending: false);

      return (response as List)
          .map((e) => Sponsor.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener patrocinadores: ${e.message}');
    }
  }

  Future<List<Sponsor>> getActiveSponsors(String clubId) async {
    if (!SupabaseService.isConfigured || _supabase == null || clubId.trim().isEmpty) {
      return _demoSponsors().where((s) => s.isActive && !s.isExpired).toList();
    }

    try {
      final response = await _supabase
          .from('sponsors')
          .select()
          .eq('club_id', clubId)
          .eq('status', 'active')
          .order('contract_start_date', ascending: false);

      return (response as List)
          .map((e) => Sponsor.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener patrocinadores activos: ${e.message}');
    }
  }

  Future<List<PublicSponsor>> getPublicSponsors(String clubSlug) async {
    if (!SupabaseService.isConfigured || _supabase == null || clubSlug.trim().isEmpty) {
      return _demoSponsors()
          .where((sponsor) => sponsor.isPublic && sponsor.isActive)
          .map((sponsor) => PublicSponsor(
                id: sponsor.id,
                name: sponsor.name,
                logoUrl: sponsor.logoUrl,
                website: sponsor.website,
              ))
          .toList();
    }

    final supabase = _supabase;
    try {
      final response = await supabase.rpc(
        'get_public_sponsors',
        params: {'target_club_slug': clubSlug},
      );

      return (response as List)
          .map((e) => PublicSponsor.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener patrocinadores públicos: ${e.message}');
    }
  }

  Future<String> createSponsor({
    required String clubId,
    required String name,
    required String? website,
    required String? contactEmail,
    required String? contactPhone,
    required DateTime contractStartDate,
    required DateTime contractEndDate,
    required double annualAmount,
    required String? benefits,
    required bool isPublic,
  }) async {
    if (!SupabaseService.isConfigured || _supabase == null) {
      return 'sponsor-${DateTime.now().millisecondsSinceEpoch}';
    }

    final supabase = _supabase;
    try {
      final result = await supabase.rpc(
        'create_sponsor',
        params: {
          'p_club_id': clubId,
          'p_name': name,
          'p_website': website,
          'p_contact_email': contactEmail,
          'p_contact_phone': contactPhone,
          'p_contract_start_date':
              contractStartDate.toIso8601String().split('T')[0],
          'p_contract_end_date': contractEndDate.toIso8601String().split('T')[0],
          'p_annual_amount': annualAmount,
          'p_benefits': benefits,
          'p_is_public': isPublic,
        },
      );

      final success = result[0]['success'] as bool;
      if (!success) {
        throw Exception(result[0]['message'] as String);
      }
      return result[0]['sponsor_id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Error al crear patrocinador: ${e.message}');
    }
  }

  Future<void> updateSponsor({
    required String sponsorId,
    required String name,
    required String? website,
    required String? contactEmail,
    required String? contactPhone,
    required double annualAmount,
    required String? benefits,
    required String status,
    required bool isPublic,
  }) async {
    if (!SupabaseService.isConfigured || _supabase == null) {
      return;
    }

    try {
      final result = await _supabase.rpc(
        'update_sponsor',
        params: {
          'p_sponsor_id': sponsorId,
          'p_name': name,
          'p_website': website,
          'p_contact_email': contactEmail,
          'p_contact_phone': contactPhone,
          'p_annual_amount': annualAmount,
          'p_benefits': benefits,
          'p_status': status,
          'p_is_public': isPublic,
        },
      );

      final success = result[0]['success'] as bool;
      if (!success) {
        throw Exception(result[0]['message'] as String);
      }
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar patrocinador: ${e.message}');
    }
  }

  List<Sponsor> _demoSponsors() {
    return [
      Sponsor(
        id: '1',
        clubId: 'demo-club',
        name: 'Cervecería San Juan',
        logoUrl: null,
        website: 'https://cerveceriasanjuan.es',
        contactEmail: 'info@cerveceriasanjuan.es',
        contactPhone: '954 123 456',
        contractStartDate: DateTime.now().subtract(const Duration(days: 180)),
        contractEndDate: DateTime.now().add(const Duration(days: 185)),
        annualAmount: 5000.0,
        benefits: 'Logo en camisetas, presencia en redes',
        status: 'active',
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now(),
      ),
      Sponsor(
        id: '2',
        clubId: 'demo-club',
        name: 'Supermercado El Barrio',
        logoUrl: null,
        website: 'https://superelmercadoelbarrio.es',
        contactEmail: 'contacto@elbarrio.es',
        contactPhone: '954 654 321',
        contractStartDate: DateTime.now().subtract(const Duration(days: 90)),
        contractEndDate: DateTime.now().add(const Duration(days: 275)),
        annualAmount: 3000.0,
        benefits: 'Logo en sitio web, mención en eventos',
        status: 'active',
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
      ),
      Sponsor(
        id: '3',
        clubId: 'demo-club',
        name: 'Taller Mecánico García',
        logoUrl: null,
        website: null,
        contactEmail: 'taller@garcia.es',
        contactPhone: '954 789 012',
        contractStartDate: DateTime.now().subtract(const Duration(days: 60)),
        contractEndDate: DateTime.now().subtract(const Duration(days: 10)),
        annualAmount: 2000.0,
        benefits: 'Soporte técnico',
        status: 'expired',
        isPublic: false,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

final sponsorRepositoryProvider = Provider<SponsorRepository>((ref) {
  final supabase = SupabaseService.isConfigured
      ? Supabase.instance.client
      : null;
  return SponsorRepository(supabase);
});

final clubSponsorsProvider =
    FutureProvider.family<List<Sponsor>, String>((ref, clubId) {
  return ref.watch(sponsorRepositoryProvider).getClubSponsors(clubId);
});

final activeSponsorsProvider =
    FutureProvider.family<List<Sponsor>, String>((ref, clubId) {
  return ref.watch(sponsorRepositoryProvider).getActiveSponsors(clubId);
});

final publicSponsorsProvider =
    FutureProvider.family<List<PublicSponsor>, String>((ref, clubSlug) {
  return ref.watch(sponsorRepositoryProvider).getPublicSponsors(clubSlug);
});
