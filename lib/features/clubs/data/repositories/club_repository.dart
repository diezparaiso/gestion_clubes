import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/club.dart';

final clubRepositoryProvider = Provider<ClubRepository>((ref) => ClubRepository());

class ClubRepository {
  Future<Club> createClub({required String publicName}) async {
    final slug = _createSlug(publicName);
    if (!SupabaseService.isConfigured) {
      return Club(id: 'demo-club', publicName: publicName.trim(), slug: slug);
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('La sesión ha expirado. Inicia sesión de nuevo.');

    final club = await client.rpc('create_club', params: {
      'club_public_name': publicName.trim(),
      'club_legal_name': publicName.trim(),
      'club_slug': slug,
    });

    return Club.fromJson(club as Map<String, dynamic>);
  }

  Future<Club> getPublicClub(String slug) async {
    if (!SupabaseService.isConfigured) return Club(id: 'demo-club', publicName: 'Club Deportivo Paraíso', slug: slug);
    final row = await Supabase.instance.client.rpc<Map<String, dynamic>>('get_public_club', params: {'target_club_slug': slug});
    return Club.fromJson(row);
  }

  String _createSlug(String value) {
    final normalized = value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'club' : normalized;
  }
}
