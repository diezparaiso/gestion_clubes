import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/club_repository.dart';
import '../../domain/entities/club.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): añade acceso público a patrocinadores.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): convierte la página pública del club en home principal con acceso al login.

class PublicClubPage extends StatefulWidget {
  const PublicClubPage({super.key, required this.clubSlug});
  final String clubSlug;

  @override
  State<PublicClubPage> createState() => _PublicClubPageState();
}

class _PublicClubPageState extends State<PublicClubPage> {
  late final Future<Club> _club;

  @override
  void initState() {
    super.initState();
    _club = ClubRepository().getPublicClub(widget.clubSlug);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _PublicAppBar(clubSlug: widget.clubSlug),
        body: FutureBuilder<Club>(
          future: _club,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Center(child: Text('Este club no está disponible.'));
            }
            return _content(context, snapshot.data!);
          },
        ),
      );

  Widget _content(BuildContext context, Club club) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 52),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 650;
                    return Column(
                      crossAxisAlignment: compact
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: theme.colorScheme.surface,
                          child: Icon(
                            Icons.sports_soccer_rounded,
                            size: 38,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          club.publicName,
                          textAlign: compact ? TextAlign.center : TextAlign.start,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Toda la actualidad del club en un solo lugar.',
                          textAlign: compact ? TextAlign.center : TextAlign.start,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: compact
                              ? WrapAlignment.center
                              : WrapAlignment.start,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: () => context.go(
                                '/club/${widget.clubSlug}/events',
                              ),
                              icon: const Icon(Icons.event_outlined),
                              label: const Text('Próximos eventos'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.go(
                                '/club/${widget.clubSlug}/news',
                              ),
                              icon: const Icon(Icons.article_outlined),
                              label: const Text('Últimas noticias'),
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Todo lo que necesitas del club',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 18),
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
                            _PublicCard(
                              width: width,
                              icon: Icons.article_outlined,
                              title: 'Noticias',
                              description: 'Últimas novedades del club.',
                              onTap: () => context.go(
                                '/club/${widget.clubSlug}/news',
                              ),
                            ),
                            _PublicCard(
                              width: width,
                              icon: Icons.event_outlined,
                              title: 'Eventos',
                              description: 'Partidos y actividades próximas.',
                              onTap: () => context.go(
                                '/club/${widget.clubSlug}/events',
                              ),
                            ),
                            _PublicCard(
                              width: width,
                              icon: Icons.groups_outlined,
                              title: 'Equipos',
                              description: 'Conoce nuestras categorías.',
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('La sección de equipos estará disponible próximamente.'),
                                ),
                              ),
                            ),
                            _PublicCard(
                              width: width,
                              icon: Icons.business_outlined,
                              title: 'Patrocinadores',
                              description: 'Empresas que apoyan al club.',
                              onTap: () => context.go(
                                '/club/${widget.clubSlug}/sponsors',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    if (club.website != null ||
                        club.instagramUrl != null ||
                        club.facebookUrl != null ||
                        club.youtubeUrl != null) ...[
                      Text('Síguenos',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (club.website != null)
                            _PublicLink(
                              icon: Icons.language,
                              label: 'Web',
                              url: club.website!,
                            ),
                          if (club.instagramUrl != null)
                            _PublicLink(
                              icon: Icons.camera_alt_outlined,
                              label: 'Instagram',
                              url: club.instagramUrl!,
                            ),
                          if (club.facebookUrl != null)
                            _PublicLink(
                              icon: Icons.facebook,
                              label: 'Facebook',
                              url: club.facebookUrl!,
                            ),
                          if (club.youtubeUrl != null)
                            _PublicLink(
                              icon: Icons.play_circle_outline,
                              label: 'YouTube',
                              url: club.youtubeUrl!,
                            ),
                        ],
                      ),
                    ],
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

class _PublicAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PublicAppBar({required this.clubSlug});
  final String clubSlug;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_soccer_rounded),
          SizedBox(width: 8),
          Text('CLUB PLATFORM'),
        ],
      ),
      actions: [
        if (MediaQuery.sizeOf(context).width >= 700) ...[
          TextButton(
            onPressed: () => context.go('/club/$clubSlug/news'),
            child: const Text('Noticias'),
          ),
          TextButton(
            onPressed: () => context.go('/club/$clubSlug/events'),
            child: const Text('Eventos'),
          ),
          TextButton(
            onPressed: () => context.go('/club/$clubSlug/sponsors'),
            child: const Text('Patrocinadores'),
          ),
        ],
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Acceder'),
          ),
        ),
      ],
    );
  }
}

class _PublicCard extends StatelessWidget {
  const _PublicCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 30),
                  const SizedBox(height: 14),
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
          ),
        ),
      );
}

class _PublicLink extends StatelessWidget {
  const _PublicLink({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        ),
        icon: Icon(icon),
        label: Text(label),
      );
}
