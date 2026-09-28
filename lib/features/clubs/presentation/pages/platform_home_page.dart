import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): crea la landing pública de la plataforma de clubes.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): añade explicación visual del flujo de incorporación.

class PlatformHomePage extends StatelessWidget {
  const PlatformHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer_rounded),
            SizedBox(width: 8),
            Text('CLUB PLATFORM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/privacy'),
            child: const Text('Privacidad'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Acceder'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 64),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 700;
                      return Column(
                        crossAxisAlignment: compact
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.sports_soccer_rounded,
                            size: compact ? 54 : 64,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'La gestión de tu club,\nen un solo lugar.',
                            textAlign:
                                compact ? TextAlign.center : TextAlign.start,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Una plataforma para organizar el día a día del club, '
                            'comunicarte con tus socios y ofrecer una web pública propia.',
                            textAlign:
                                compact ? TextAlign.center : TextAlign.start,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            alignment: compact
                                ? WrapAlignment.center
                                : WrapAlignment.start,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: () => context.go(
                                  '/solicitar-incorporacion',
                                ),
                                icon: const Icon(Icons.add_business_outlined),
                                label: const Text('Incorporar mi club'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => context.go('/login'),
                                icon: const Icon(Icons.login),
                                label: const Text('Ya tengo acceso'),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Todo lo importante del club',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 900
                              ? 3
                              : constraints.maxWidth >= 600
                                  ? 2
                                  : 1;
                          final width = (constraints.maxWidth -
                                  (columns - 1) * 12) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _FeatureCard(
                                width: width,
                                icon: Icons.groups_outlined,
                                title: 'Socios',
                                description:
                                    'Gestiona miembros, accesos y la información del club.',
                              ),
                              _FeatureCard(
                                width: width,
                                icon: Icons.account_balance_wallet_outlined,
                                title: 'Tesorería',
                                description:
                                    'Registra ingresos y gastos y consulta la situación del club.',
                              ),
                              _FeatureCard(
                                width: width,
                                icon: Icons.confirmation_number_outlined,
                                title: 'Rifas y porras',
                                description:
                                    'Prepara sorteos y experiencias digitales para tus socios.',
                              ),
                              _FeatureCard(
                                width: width,
                                icon: Icons.campaign_outlined,
                                title: 'Noticias y avisos',
                                description:
                                    'Mantén informados a jugadores, familias y socios.',
                              ),
                              _FeatureCard(
                                width: width,
                                icon: Icons.business_outlined,
                                title: 'Patrocinadores',
                                description:
                                    'Da visibilidad a las empresas que apoyan al club.',
                              ),
                              _FeatureCard(
                                width: width,
                                icon: Icons.language_outlined,
                                title: 'Web pública',
                                description:
                                    'Ofrece al club un escaparate público con sus contenidos.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest,
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cómo se incorpora un club?',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'El proceso está pensado para empezar de forma sencilla y separar '
                        'el alta del club de la configuración de cobros.',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 900
                              ? 4
                              : constraints.maxWidth >= 600
                                  ? 2
                                  : 1;
                          final width = (constraints.maxWidth -
                                  (columns - 1) * 12) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _OnboardingStepCard(
                                width: width,
                                number: '1',
                                icon: Icons.assignment_outlined,
                                title: 'Solicitud',
                                description:
                                    'El club facilita sus datos básicos y una persona de contacto.',
                              ),
                              _OnboardingStepCard(
                                width: width,
                                number: '2',
                                icon: Icons.fact_check_outlined,
                                title: 'Revisión',
                                description:
                                    'El equipo de soporte comprueba la solicitud antes del alta.',
                              ),
                              _OnboardingStepCard(
                                width: width,
                                number: '3',
                                icon: Icons.space_dashboard_outlined,
                                title: 'Alta del club',
                                description:
                                    'Se crea su espacio de gestión y se configura el acceso del responsable.',
                              ),
                              _OnboardingStepCard(
                                width: width,
                                number: '4',
                                icon: Icons.account_balance_outlined,
                                title: 'Cobros',
                                description:
                                    'Cuando proceda, la configuración bancaria se realizará directamente con Stripe.',
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'La plataforma no solicita datos bancarios en la solicitud inicial. '
                              'La integración futura con Stripe está diseñada para que los datos '
                              'financieros sean recopilados por Stripe durante su propio onboarding.',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 650;
                          return Column(
                            crossAxisAlignment: compact
                                ? CrossAxisAlignment.center
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Quieres incorporar tu club?',
                                textAlign: compact
                                    ? TextAlign.center
                                    : TextAlign.start,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Déjanos los datos básicos del club y una persona del equipo '
                                'de soporte podrá revisar la solicitud. No introduzcas datos bancarios.',
                                textAlign: compact
                                    ? TextAlign.center
                                    : TextAlign.start,
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => context.go(
                                  '/solicitar-incorporacion',
                                ),
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Solicitar incorporación'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStepCard extends StatelessWidget {
  const _OnboardingStepCard({
    required this.width,
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final double width;
  final String number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 16, child: Text(number)),
                  const SizedBox(width: 10),
                  Icon(icon, size: 26),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(description),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
  });

  final double width;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 30),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(description),
              ],
            ),
          ),
        ),
      );
}
