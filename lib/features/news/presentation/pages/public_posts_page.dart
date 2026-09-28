import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/post_repository.dart';
import '../../domain/entities/post.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Muestra la imagen opcional de las noticias públicas.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): añade navegación pública consistente y acceso al login.
class PublicPostsPage extends StatefulWidget {
  const PublicPostsPage({super.key, required this.clubSlug});
  final String clubSlug;

  @override
  State<PublicPostsPage> createState() => _PublicPostsPageState();
}

class _PublicPostsPageState extends State<PublicPostsPage> {
  late final Future<List<Post>> _posts;

  @override
  void initState() {
    super.initState();
    _posts = PostRepository().listPublicPosts(widget.clubSlug);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Noticias del club'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Acceder'),
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<Post>>(
          future: _posts,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return const Center(child: Text('No se han podido cargar las noticias.'));
            final posts = snapshot.data!;
            if (posts.isEmpty) return const Center(child: Text('Todavía no hay noticias publicadas.'));
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: posts.length,
              separatorBuilder: (_, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.imageUrl != null && post.imageUrl!.trim().isNotEmpty)
                        Image.network(
                          post.imageUrl!,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.title, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(post.body),
                            if (post.publishedAt != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                '${post.publishedAt!.day.toString().padLeft(2, '0')}/${post.publishedAt!.month.toString().padLeft(2, '0')}/${post.publishedAt!.year}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
}
