// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Añade edición y borrado de noticias y muestra todos los estados.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Permite copiar el enlace público de noticias.
import '../../../auth/application/auth_controller.dart';
import '../../../dashboard/presentation/widgets/club_navigation_app_bar.dart';
import '../../data/repositories/post_repository.dart';
import '../../domain/entities/post.dart';
import '../../../clubs/data/repositories/club_repository.dart';

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
      appBar: const ClubNavigationAppBar(title: 'Noticias'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Noticias del club', style: Theme.of(context).textTheme.headlineMedium)),
            IconButton(tooltip: 'Copiar enlace público', onPressed: () async { final clubId = ref.read(authControllerProvider).clubId; if (clubId == null) return; final club = await ref.read(clubRepositoryProvider).getClubById(clubId); final url = Uri.base.replace(path: '/club/${club.slug}/news').toString(); await Clipboard.setData(ClipboardData(text: url)); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace público de noticias copiado.'))); }, icon: const Icon(Icons.link_outlined)), const SizedBox(width: 8),
            FilledButton.icon(onPressed: () => _showPostDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Nueva noticia')),
          ]),
          const SizedBox(height: 8),
          const Text('Publica avisos y novedades para la comunidad.'),
          const SizedBox(height: 24),
          Expanded(child: posts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Center(child: Text('No se han podido cargar las noticias.')),
            data: (items) => items.isEmpty
                ? const Center(child: Text('Todavía no hay noticias.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final post = items[index];
                      return _PostCard(
                        post: post,
                        onEdit: () => _showPostDialog(context, ref, post: post),
                        onDelete: () => _deletePost(context, ref, post),
                      );
                    },
                  ),
          )),
        ]),
      ),
    );
  }

  Future<void> _showPostDialog(BuildContext context, WidgetRef ref, {Post? post}) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _PostDialog(post: post));
    if (saved == true) ref.invalidate(postsProvider);
  }

  Future<void> _deletePost(BuildContext context, WidgetRef ref, Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar noticia'),
        content: Text('¿Quieres eliminar «${post.title}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(postRepositoryProvider).deletePost(post.id);
      ref.invalidate(postsProvider);
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se ha podido eliminar la noticia.')));
    }
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onEdit, required this.onDelete});
  final Post post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _statusLabel() {
    switch (post.status) {
      case PostStatus.published: return 'Publicada';
      case PostStatus.draft: return 'Borrador';
      case PostStatus.archived: return 'Archivada';
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: const CircleAvatar(child: Icon(Icons.article_outlined)),
      title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Chip(label: Text(_statusLabel()), side: BorderSide.none),
        PopupMenuButton<String>(
          onSelected: (value) { if (value == 'edit') onEdit(); if (value == 'delete') onDelete(); },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ]),
    ),
  );
}

class _PostDialog extends ConsumerStatefulWidget {
  const _PostDialog({this.post});
  final Post? post;
  @override
  ConsumerState<_PostDialog> createState() => _PostDialogState();
}

class _PostDialogState extends ConsumerState<_PostDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late PostStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post?.title ?? '');
    _bodyController = TextEditingController(text: widget.post?.body ?? '');
    _status = widget.post?.status ?? PostStatus.draft;
  }

  @override
  void dispose() { _titleController.dispose(); _bodyController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    setState(() => _saving = true);
    try {
      if (widget.post == null) {
        await ref.read(postRepositoryProvider).createPost(clubId: clubId, title: _titleController.text, body: _bodyController.text, status: _status);
      } else {
        await ref.read(postRepositoryProvider).updatePost(postId: widget.post!.id, title: _titleController.text, body: _bodyController.text, status: _status);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se ha podido guardar: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.post == null ? 'Nueva noticia' : 'Editar noticia'),
    content: SizedBox(width: 460, child: Form(
      key: _formKey,
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _bodyController, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'Contenido'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null),
        const SizedBox(height: 12),
        DropdownButtonFormField<PostStatus>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: const [
            DropdownMenuItem(value: PostStatus.draft, child: Text('Borrador')),
            DropdownMenuItem(value: PostStatus.published, child: Text('Publicada')),
            DropdownMenuItem(value: PostStatus.archived, child: Text('Archivada')),
          ],
          onChanged: (value) => setState(() => _status = value ?? PostStatus.draft),
        ),
      ]),
    ))),
    actions: [
      TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
      FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar')),
    ],
  );
}
