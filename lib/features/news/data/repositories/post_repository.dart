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
    if (!SupabaseService.isConfigured) {
      final post = Post(id: 'post-${_demoPosts.length + 1}', title: title.trim(), body: body.trim(), status: status, publishedAt: status == PostStatus.published ? DateTime.now() : null, createdAt: DateTime.now());
      _demoPosts.insert(0, post);
      return post;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('La sesión ha expirado.');
    final row = await Supabase.instance.client.from('posts').insert({'club_id': clubId, 'title': title.trim(), 'body': body.trim(), 'status': status.name, 'published_at': status == PostStatus.published ? DateTime.now().toIso8601String() : null, 'author_id': userId}).select('id, title, body, status, image_url, published_at, created_at').single();
    return Post.fromJson(row);
  }

  static final _demoPosts = <Post>[
    Post(id: 'post-1', title: 'Comienza la nueva temporada', body: 'Ya está disponible toda la información de la temporada del club.', status: PostStatus.published, publishedAt: DateTime(2026, 9, 1), createdAt: DateTime(2026, 9, 1)),
    Post(id: 'post-2', title: 'Reunión de familias', body: 'La próxima reunión tendrá lugar en las instalaciones del club.', status: PostStatus.draft, createdAt: DateTime(2026, 9, 2)),
  ];
}