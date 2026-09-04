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
    if (!SupabaseService.isConfigured) return Club(id: 'demo-club', publicName: 'Club Deportivo Paraíso', slug: slug, website: 'https://clubparaiso.example');
    final row = await Supabase.instance.client.rpc<Map<String, dynamic>>('get_public_club', params: {'target_club_slug': slug});
    return Club.fromJson(row);
  }

  Future<Club> getClubById(String clubId) async {
    if (!SupabaseService.isConfigured) return Club(id: clubId, publicName: 'Club Deportivo Paraíso', slug: 'club-paraiso', website: 'https://clubparaiso.example');
    final row = await Supabase.instance.client.from('clubs').select('id, public_name, slug, website, instagram_url, facebook_url, youtube_url').eq('id', clubId).single();
    return Club.fromJson(row);
  }

  Future<Club> updatePublicProfile({required String clubId, required String publicName, String? website, String? instagramUrl, String? facebookUrl, String? youtubeUrl}) async {
    if (!SupabaseService.isConfigured) return Club(id: clubId, publicName: publicName.trim(), slug: 'club-paraiso', website: website, instagramUrl: instagramUrl, facebookUrl: facebookUrl, youtubeUrl: youtubeUrl);
    final row = await Supabase.instance.client.from('clubs').update({'public_name': publicName.trim(), 'website': _nullable(website), 'instagram_url': _nullable(instagramUrl), 'facebook_url': _nullable(facebookUrl), 'youtube_url': _nullable(youtubeUrl)}).eq('id', clubId).select('id, public_name, slug, website, instagram_url, facebook_url, youtube_url').single();
    return Club.fromJson(row);
  }

  String? _nullable(String? value) => value == null || value.trim().isEmpty ? null : value.trim();

  String _createSlug(String value) {
    final normalized = value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'club' : normalized;
  }
}
