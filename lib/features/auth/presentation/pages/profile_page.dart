import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/auth_controller.dart';
import '../../../dashboard/presentation/widgets/club_navigation_app_bar.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): completa cambio de contraseña tras recuperación por email.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): cierre UX del perfil; responsive, validación y visibilidad del estado de guardado.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): mejora estructura visual, estados y accesibilidad del formulario de contraseña.

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
  String? _error;

  @override
  void dispose() {
    _current.dispose(); _newPassword.dispose(); _confirm.dispose(); super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
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
      final wasRecovery = ref.read(authControllerProvider).passwordRecovery;
      ref.read(authControllerProvider.notifier).clearPasswordChangeRequirement();
      _current.clear(); _newPassword.clear(); _confirm.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada correctamente.')));
      if (wasRecovery && mounted) {
        await ref.read(authControllerProvider.notifier).signOut();
        return;
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se ha podido cambiar la contraseña. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final email = auth.email ?? Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: widget.forcePasswordChange
          ? AppBar(title: const Text('Cambia tu contraseña'))
          : ClubNavigationAppBar(title: 'Mi perfil'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          return ListView(
            padding: EdgeInsets.all(compact ? 16 : 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 20 : 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Cuenta', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(email, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            Text('Cambiar contraseña', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            if (widget.forcePasswordChange)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'Por seguridad, debes cambiar la contraseña inicial antes de continuar.',
                                  style: TextStyle(color: theme.colorScheme.primary),
                                ),
                              ),
                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                                ),
                              ),
                            if (!auth.passwordRecovery) ...[
                              TextFormField(
                                controller: _current,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.password],
                                decoration: const InputDecoration(
                                  labelText: 'Contraseña actual',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _newPassword,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: const InputDecoration(
                                labelText: 'Nueva contraseña',
                                prefixIcon: Icon(Icons.lock_reset),
                              ),
                              validator: (v) => v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirm,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: const InputDecoration(
                                labelText: 'Repite la nueva contraseña',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                              validator: (v) => v != _newPassword.text ? 'Las contraseñas no coinciden' : null,
                              onFieldSubmitted: (_) {
                                if (!_saving) _changePassword();
                              },
                            ),
                            CheckboxListTile(
                              value: !_obscure,
                              onChanged: (v) => setState(() => _obscure = !(v ?? false)),
                              title: const Text('Mostrar contraseña'),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: _saving ? null : _changePassword,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(_saving ? 'Guardando…' : 'Cambiar contraseña'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }}
