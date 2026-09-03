import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signUp(_emailController.text.trim(), _passwordController.text);
    if (mounted && ref.read(authControllerProvider).status == AuthStatus.needsClub) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.signingIn;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('CLUB PLATFORM', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.7, color: Color(0xFF14213D))),
              const SizedBox(height: 42),
              Text('Crea tu cuenta', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Empieza a organizar tu club hoy.'),
              const SizedBox(height: 28),
              Card(child: Padding(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)), validator: (value) => value == null || !value.contains('@') ? 'Introduce un email válido' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)), validator: (value) => value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null),
                if (authState.errorMessage != null) ...[const SizedBox(height: 16), Text(authState.errorMessage!, style: TextStyle(color: Colors.red))],
                const SizedBox(height: 24),
                FilledButton(onPressed: isLoading ? null : _submit, child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear cuenta'))),
                const SizedBox(height: 12),
                TextButton(onPressed: () => context.go('/login'), child: const Text('Ya tengo una cuenta')),
              ])))),
            ],),
          ),
        ),
      ),
    );
  }
}
