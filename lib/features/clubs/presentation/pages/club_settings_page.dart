import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/club_repository.dart';
import '../../domain/entities/club.dart';

class ClubSettingsPage extends ConsumerWidget {
  const ClubSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubId = ref.watch(authControllerProvider).clubId;
    if (clubId == null) return const Scaffold(body: Center(child: Text('No hay un club seleccionado.')));
    return FutureBuilder<Club>(future: ref.read(clubRepositoryProvider).getClubById(clubId), builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (snapshot.hasError || snapshot.data == null) return const Scaffold(body: Center(child: Text('No se ha podido cargar la configuración.')));
      return _ClubSettingsForm(club: snapshot.data!);
    });
  }
}

class _ClubSettingsForm extends ConsumerStatefulWidget {
  const _ClubSettingsForm({required this.club});
  final Club club;

  @override
  ConsumerState<_ClubSettingsForm> createState() => _ClubSettingsFormState();
}

class _ClubSettingsFormState extends ConsumerState<_ClubSettingsForm> {
  late final TextEditingController _nameController = TextEditingController(text: widget.club.publicName);
  late final TextEditingController _websiteController = TextEditingController(text: widget.club.website);
  late final TextEditingController _instagramController = TextEditingController(text: widget.club.instagramUrl);
  late final TextEditingController _facebookController = TextEditingController(text: widget.club.facebookUrl);
  late final TextEditingController _youtubeController = TextEditingController(text: widget.club.youtubeUrl);
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() { _nameController.dispose(); _websiteController.dispose(); _instagramController.dispose(); _facebookController.dispose(); _youtubeController.dispose(); super.dispose(); }

  String? _urlValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    return uri == null || !{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty ? 'Introduce una URL válida' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(clubRepositoryProvider).updatePublicProfile(clubId: widget.club.id, publicName: _nameController.text, website: _websiteController.text, instagramUrl: _instagramController.text, facebookUrl: _facebookController.text, youtubeUrl: _youtubeController.text);
      if (mounted) { setState(() => _saving = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada.'))); }
    } on PostgrestException catch (error) {
      if (mounted) setState(() { _saving = false; _error = error.message; });
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'No se ha podido guardar la configuración.'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Configuración')), body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [Text('Perfil público', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 8), const Text('Estos datos se mostrarán en la página pública del club.'), const SizedBox(height: 24), Card(child: Padding(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre público'), validator: (value) => value == null || value.trim().length < 3 ? 'Introduce al menos 3 caracteres' : null), const SizedBox(height: 12), TextFormField(controller: _websiteController, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Página web'), validator: _urlValidator), const SizedBox(height: 12), TextFormField(controller: _instagramController, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Instagram'), validator: _urlValidator), const SizedBox(height: 12), TextFormField(controller: _facebookController, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Facebook'), validator: _urlValidator), const SizedBox(height: 12), TextFormField(controller: _youtubeController, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'YouTube'), validator: _urlValidator), if (_error != null) ...[const SizedBox(height: 16), Text(_error!, style: const TextStyle(color: Colors.red))], const SizedBox(height: 24), Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: const Text('Guardar cambios'))]))))]));
}