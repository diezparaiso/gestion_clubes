import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/post_repository.dart';
import '../../domain/entities/post.dart';

final postsProvider = FutureProvider<List<Post>>((ref) {
  final clubId = ref.watch(authControllerProvider).clubId;
  if (clubId == null) return Future.value(const []);
  return ref.watch(postRepositoryProvider).listPosts(clubId);
});

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Noticias')),
      body: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('Noticias del club', style: Theme.of(context).textTheme.headlineMedium)), FilledButton.icon(onPressed: () => _showCreateDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Nueva noticia'))]),
        const SizedBox(height: 8),
        const Text('Publica avisos y novedades para la comunidad.'),
        const SizedBox(height: 24),
        Expanded(child: posts.when(loading: () => const Center(child: CircularProgressIndicator()), error: (error, stack) => const Center(child: Text('No se han podido cargar las noticias.')), data: (items) => items.isEmpty ? const Center(child: Text('Todavía no hay noticias.')) : ListView.separated(itemCount: items.length, separatorBuilder: (_, index) => const SizedBox(height: 12), itemBuilder: (context, index) => _PostCard(post: items[index])))),
      ])),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => const _CreatePostDialog());
    if (saved == true) ref.invalidate(postsProvider);
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.all(16), leading: const CircleAvatar(child: Icon(Icons.article_outlined)), title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: Chip(label: Text(post.status == PostStatus.published ? 'Publicada' : 'Borrador'), side: BorderSide.none)));
}

class _CreatePostDialog extends ConsumerStatefulWidget {
  const _CreatePostDialog();
  @override
  ConsumerState<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends ConsumerState<_CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  PostStatus _status = PostStatus.draft;
  bool _saving = false;

  @override
  void dispose() { _titleController.dispose(); _bodyController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(postRepositoryProvider).createPost(clubId: clubId, title: _titleController.text, body: _bodyController.text, status: _status);
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException {
      if (mounted) setState(() => _saving = false);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Nueva noticia'), content: SizedBox(width: 460, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null), const SizedBox(height: 12), TextFormField(controller: _bodyController, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'Contenido'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null), const SizedBox(height: 12), DropdownButtonFormField<PostStatus>(initialValue: _status, decoration: const InputDecoration(labelText: 'Estado'), items: const [DropdownMenuItem(value: PostStatus.draft, child: Text('Borrador')), DropdownMenuItem(value: PostStatus.published, child: Text('Publicada'))], onChanged: (value) => setState(() => _status = value ?? PostStatus.draft))])))), actions: [TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')), FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'))]);
}