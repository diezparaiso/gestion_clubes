import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_controller.dart';

class ClubOnboardingPage extends ConsumerStatefulWidget {
  const ClubOnboardingPage({super.key});

  @override
  ConsumerState<ClubOnboardingPage> createState() => _ClubOnboardingPageState();
}

class _ClubOnboardingPageState extends ConsumerState<ClubOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _clubNameController = TextEditingController();

  @override
  void dispose() {
    _clubNameController.dispose();
    super.dispose();
  }

  Future<void> _createClub() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).createClub(_clubNameController.text);
    if (mounted && ref.read(authControllerProvider).status == AuthStatus.signedIn) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.creatingClub;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('CLUB PLATFORM', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.7, color: Color(0xFF14213D))),
              const SizedBox(height: 42),
              Text('Crea tu club', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Solo necesitamos unos datos para preparar tu espacio de trabajo.'),
              const SizedBox(height: 28),
              Card(child: Padding(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextFormField(controller: _clubNameController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nombre público del club', prefixIcon: Icon(Icons.shield_outlined)), validator: (value) => value == null || value.trim().length < 3 ? 'Introduce al menos 3 caracteres' : null),
                const SizedBox(height: 12),
                const Text('Podrás completar los datos fiscales, logo y redes sociales desde Configuración.', style: TextStyle(fontSize: 13)),
                if (authState.errorMessage != null) ...[const SizedBox(height: 16), Text(authState.errorMessage!, style: TextStyle(color: Colors.red))],
                const SizedBox(height: 24),
                FilledButton.icon(onPressed: isLoading ? null : _createClub, icon: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward_rounded), label: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Continuar'))),
              ])))),
            ],),
          ),
        ),
      ),
    );
  }
}
