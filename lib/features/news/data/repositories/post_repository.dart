// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Completa CRUD de noticias y controla publicación.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/post.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) => PostRepository());

class PostRepository {
  Future<List<Post>> listPosts(String clubId) async {
    if (!SupabaseService.isConfigured) return List.unmodifiable(_demoPosts);
    final rows = await Supabase.instance.client.from('posts').select('id, title, body, status, image_url, published_at, created_at').eq('club_id', clubId).order('created_at', ascending: false);
    return rows.map(Post.fromJson).toList();
  }

  Future<List<Post>> listPublicPosts(String clubSlug) async {
    if (!SupabaseService.isConfigured) return List.unmodifiable(_demoPosts.where((post) => post.status == PostStatus.published));
    final rows = await Supabase.instance.client.rpc<List<dynamic>>('get_public_posts', params: {'target_club_slug': clubSlug});
    return rows.map((row) => Post.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<Post> createPost({required String clubId, required String title, required String body, required PostStatus status}) async {
    final normalizedTitle = title.trim();
    final normalizedBody = body.trim();
    if (normalizedTitle.isEmpty || normalizedBody.isEmpty) throw FormatException('El título y el contenido son obligatorios.');
    if (!SupabaseService.isConfigured) {
      final post = Post(id: 'post-' + (_demoPosts.length + 1).toString(), title: normalizedTitle, body: normalizedBody, status: status, publishedAt: status == PostStatus.published ? DateTime.now() : null, createdAt: DateTime.now());
      _demoPosts.insert(0, post);
      return post;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw AuthException('La sesión ha expirado.');
    final row = await Supabase.instance.client.from('posts').insert({'club_id': clubId, 'title': normalizedTitle, 'body': normalizedBody, 'status': status.name, 'published_at': status == PostStatus.published ? DateTime.now().toIso8601String() : null, 'author_id': userId}).select('id, title, body, status, image_url, published_at, created_at').single();
    return Post.fromJson(row);
  }

  Future<void> updatePost({required String postId, required String title, required String body, required PostStatus status}) async {
    final normalizedTitle = title.trim();
    final normalizedBody = body.trim();
    if (normalizedTitle.isEmpty || normalizedBody.isEmpty) throw FormatException('El título y el contenido son obligatorios.');
    if (!SupabaseService.isConfigured) {
      final index = _demoPosts.indexWhere((post) => post.id == postId);
      if (index < 0) throw StateError('Noticia no encontrada.');
      final previous = _demoPosts[index];
      _demoPosts[index] = Post(id: previous.id, title: normalizedTitle, body: normalizedBody, status: status, imageUrl: previous.imageUrl, publishedAt: status == PostStatus.published ? (previous.publishedAt ?? DateTime.now()) : null, createdAt: previous.createdAt);
      return;
    }
    await Supabase.instance.client.from('posts').update({'title': normalizedTitle, 'body': normalizedBody, 'status': status.name, 'published_at': status == PostStatus.published ? DateTime.now().toIso8601String() : null}).eq('id', postId);
  }

  Future<void> deletePost(String postId) async {
    if (!SupabaseService.isConfigured) {
      _demoPosts.removeWhere((post) => post.id == postId);
      return;
    }
    await Supabase.instance.client.from('posts').delete().eq('id', postId);
  }

  static final _demoPosts = <Post>[
    Post(id: 'post-1', title: 'Comienza la nueva temporada', body: 'Ya está disponible toda la información de la temporada del club.', status: PostStatus.published, publishedAt: DateTime(2026, 9, 1), createdAt: DateTime(2026, 9, 1)),
    Post(id: 'post-2', title: 'Reunión de familias', body: 'La próxima reunión tendrá lugar en las instalaciones del club.', status: PostStatus.draft, createdAt: DateTime(2026, 9, 2)),
  ];
}
