import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_controller.dart';
import '../../../../core/utils/safe_internal_location.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): permite entrar en clubes existentes donde el usuario tenga acceso activo.

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
    final destination = _continueDestination(context);
    await ref.read(authControllerProvider.notifier).createClub(_clubNameController.text);
    if (mounted && ref.read(authControllerProvider).status == AuthStatus.signedIn) {
      context.go(destination);
    }
  }

  Future<void> _selectClub(ClubAccess club, String destination) async {
    await ref.read(authControllerProvider.notifier).selectClub(club);
    if (mounted) context.go(destination);
  }

  String _continueDestination(BuildContext context) {
    final requestedLocation = GoRouterState.of(context).uri.queryParameters['continue'];
    return safeInternalLocation(requestedLocation) ?? '/dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final clubs = ref.watch(availableClubsProvider);
    final isLoading = authState.status == AuthStatus.creatingClub;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLUB PLATFORM',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: Color(0xFF14213D),
                  ),
                ),
                const SizedBox(height: 42),
                Text('Elige tu club', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text(
                  'Puedes entrar en un club al que ya tengas acceso o crear uno nuevo.',
                ),
                const SizedBox(height: 28),
                clubs.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No se han podido cargar tus clubes.',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text('Puedes crear uno nuevo o reintentarlo.\\n$error'),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => ref.invalidate(availableClubsProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mis clubes', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        ...items.map(
                          (club) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE4B363),
                                child: Icon(Icons.shield_outlined, color: Color(0xFF14213D)),
                              ),
                              title: Text(
                                club.clubName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(club.roleLabel),
                              trailing: const Icon(Icons.arrow_forward_rounded),
                              onTap: () => _selectClub(club, _continueDestination(context)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 28),
                      ],
                    );
                  },
                ),
                Text('Crear un club nuevo', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _clubNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombre público del club',
                              prefixIcon: Icon(Icons.shield_outlined),
                            ),
                            validator: (value) => value == null || value.trim().length < 3
                                ? 'Introduce al menos 3 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Podrás completar los datos fiscales, logo y redes sociales desde Configuración.',
                            style: TextStyle(fontSize: 13),
                          ),
                          if (authState.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(authState.errorMessage!, style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: isLoading ? null : _createClub,
                            icon: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add_business_outlined),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Crear club'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
