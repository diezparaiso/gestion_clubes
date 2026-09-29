import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../dashboard/presentation/widgets/club_navigation_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Añade acceso directo a la gestión de usuarios y permisos.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): Separa consulta y edición mediante club_settings_manage.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): mejora responsive de cabecera y acciones de configuración.

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/club_repository.dart';
import '../../domain/entities/club.dart';

class ClubSettingsPage extends ConsumerStatefulWidget {
  const ClubSettingsPage({super.key});

  @override
  ConsumerState<ClubSettingsPage> createState() => _ClubSettingsPageState();
}

class _ClubSettingsPageState extends ConsumerState<ClubSettingsPage> {
  Future<Club?>? _clubFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final clubId = ref.read(authControllerProvider).clubId;
    _clubFuture = clubId == null
        ? Future.value(null)
        : ref.read(clubRepositoryProvider).getClubById(clubId);
  }

  void _retry() {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ClubNavigationAppBar(title: 'Configuración'),
      body: FutureBuilder<Club?>(
        future: _clubFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40),
                  const SizedBox(height: 12),
                  const Text('No se ha podido cargar la configuración.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final club = snapshot.data;
          if (club == null) {
            return const Center(child: Text('No hay un club seleccionado.'));
          }
          return _ClubSettingsForm(club: club);
        },
      ),
    );
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
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canManage = ClubRolePermissions.has(auth.role, 'club_settings_manage');
    return Scaffold(
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final title = Text(
              'Perfil público',
              style: Theme.of(context).textTheme.headlineMedium,
            );
            final accessButton = OutlinedButton.icon(
              onPressed: ClubRolePermissions.has(auth.role, 'access_manage')
                  ? () => context.push('/settings/access')
                  : null,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Usuarios y permisos'),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: accessButton),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: title),
                accessButton,
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        const Text('Estos datos se mostrarán en la página pública del club.'),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    enabled: canManage,
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre público'),
                    validator: (value) => value == null || value.trim().length < 3
                        ? 'Introduce al menos 3 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: canManage,
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'Página web'),
                    validator: _urlValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: canManage,
                    controller: _instagramController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'Instagram'),
                    validator: _urlValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: canManage,
                    controller: _facebookController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'Facebook'),
                    validator: _urlValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: canManage,
                    controller: _youtubeController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'YouTube'),
                    validator: _urlValidator,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final url = Uri.base.replace(path: '/club/${widget.club.slug}').toString();
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enlace público del club copiado.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.link_outlined),
                      label: const Text('Copiar enlace público'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: canManage && !_saving ? _save : null,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }
}