import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/club.dart';

final clubRepositoryProvider = Provider<ClubRepository>((ref) => ClubRepository());

class ClubRepository {
  static const _slugPattern = r'^[a-z0-9]+(?:-[a-z0-9]+)*$';

  static String normalizeSlug(String value) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
      'ý': 'y',
      'ÿ': 'y',
    };

    var normalized = value.trim().toLowerCase();
    for (final entry in replacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String? validateSlug(String value) {
    final slug = normalizeSlug(value);
    if (!RegExp(_slugPattern).hasMatch(slug)) {
      return 'El nombre debe incluir letras o números para crear un identificador válido.';
    }
    return null;
  }

  static bool isSlugConflict({
    required String? code,
    String? message,
    Object? details,
    Object? hint,
  }) {
    if (code != '23505') return false;
    final errorText = [message, details, hint]
        .whereType<Object>()
        .map((value) => value.toString())
        .join(' ');
    return errorText.contains('clubs_slug_key');
  }

  static String creationErrorMessage({
    required String? code,
    String? message,
    Object? details,
    Object? hint,
  }) {
    if (isSlugConflict(
      code: code,
      message: message,
      details: details,
      hint: hint,
    )) {
      return 'Ese identificador ya está en uso, elige otro.';
    }
    return 'No se ha podido crear el club. Inténtalo de nuevo.';
  }

  Future<Club> createClub({required String publicName}) async {
    final slug = normalizeSlug(publicName);
    final slugError = validateSlug(publicName);
    if (slugError != null) throw FormatException(slugError);

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
}
