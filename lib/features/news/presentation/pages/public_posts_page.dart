import 'package:flutter/material.dart';

import '../../data/repositories/post_repository.dart';
import '../../domain/entities/post.dart';

class PublicPostsPage extends StatefulWidget {
  const PublicPostsPage({super.key, required this.clubSlug});
  final String clubSlug;

  @override
  State<PublicPostsPage> createState() => _PublicPostsPageState();
}

class _PublicPostsPageState extends State<PublicPostsPage> {
  late final Future<List<Post>> _posts;

  @override
  void initState() { super.initState(); _posts = PostRepository().listPublicPosts(widget.clubSlug); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Noticias del club')),
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
                return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(post.title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text(post.body), if (post.publishedAt != null) ...[const SizedBox(height: 12), Text('${post.publishedAt!.day}/${post.publishedAt!.month}/${post.publishedAt!.year}', style: Theme.of(context).textTheme.bodySmall)]])));
              },
            );
          },
        ),
      );
}