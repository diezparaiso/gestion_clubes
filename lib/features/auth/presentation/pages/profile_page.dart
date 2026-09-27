import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/auth_controller.dart';
import '../../../dashboard/presentation/widgets/club_navigation_app_bar.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): completa cambio de contraseña tras recuperación por email.

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, this.forcePasswordChange = false});
  final bool forcePasswordChange;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose(); _newPassword.dispose(); _confirm.dispose(); super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final auth = ref.read(authControllerProvider);
      final email = client.auth.currentUser?.email;
      if (email == null) throw Exception('No se ha encontrado el email de la cuenta.');
      if (!auth.passwordRecovery) {
        await client.auth.signInWithPassword(email: email, password: _current.text);
      }
      await client.auth.updateUser(UserAttributes(password: _newPassword.text));
      await client.from('profiles').update({'must_change_password': false}).eq('id', client.auth.currentUser!.id);
      if (!mounted) return;
      ref.read(authControllerProvider.notifier).clearPasswordChangeRequirement();
      _current.clear(); _newPassword.clear(); _confirm.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada correctamente.')));
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se ha podido cambiar la contraseña: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: widget.forcePasswordChange
          ? AppBar(title: const Text('Cambia tu contraseña'))
          : ClubNavigationAppBar(title: 'Mi perfil'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(auth.email ?? Supabase.instance.client.auth.currentUser?.email ?? '', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    if (widget.forcePasswordChange) const Text('Por seguridad, debes cambiar la contraseña inicial antes de continuar.'),
                    if (!auth.passwordRecovery)
                      TextFormField(controller: _current, obscureText: _obscure, decoration: const InputDecoration(labelText: 'Contraseña actual'), validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null),
                    TextFormField(controller: _newPassword, obscureText: _obscure, decoration: const InputDecoration(labelText: 'Nueva contraseña'), validator: (v) => v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null),
                    TextFormField(controller: _confirm, obscureText: _obscure, decoration: const InputDecoration(labelText: 'Repite la nueva contraseña'), validator: (v) => v != _newPassword.text ? 'Las contraseñas no coinciden' : null),
                    CheckboxListTile(value: !_obscure, onChanged: (v) => setState(() => _obscure = !(v ?? false)), title: const Text('Mostrar contraseña'), contentPadding: EdgeInsets.zero),
                    const SizedBox(height: 12),
                    FilledButton.icon(onPressed: _saving ? null : _changePassword, icon: const Icon(Icons.lock_reset), label: const Text('Cambiar contraseña')),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
