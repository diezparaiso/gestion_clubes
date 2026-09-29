import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/club_repository.dart';
import '../../domain/entities/club.dart';
import '../../../events/data/repositories/event_repository.dart';
import '../../../events/domain/entities/event.dart';
import '../../../news/data/repositories/post_repository.dart';
import '../../../news/domain/entities/post.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): añade acceso público a patrocinadores.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): convierte la página pública del club en home principal con acceso al login.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): incorpora actualidad real de noticias y eventos públicos.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-29): añade reintento a la carga del club y de su actualidad pública.

class PublicClubPage extends StatefulWidget {
  const PublicClubPage({super.key, required this.clubSlug});
  final String clubSlug;

  @override
  State<PublicClubPage> createState() => _PublicClubPageState();
}

class _PublicClubPageState extends State<PublicClubPage> {
  late Future<Club> _club;
  late Future<List<ClubEvent>> _events;
  late Future<List<Post>> _posts;

  @override
  void initState() {
    super.initState();
    _loadClub();
    _loadContent();
  }

  void _loadClub() {
    _club = ClubRepository().getPublicClub(widget.clubSlug);
  }

  void _loadContent() {
    _events = EventRepository().listPublicEvents(widget.clubSlug);
    _posts = PostRepository().listPublicPosts(widget.clubSlug);
  }

  void _retryClub() {
    setState(() => _loadClub());
  }

  void _retryContent() {
    setState(() => _loadContent());
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 40),
                      const SizedBox(height: 12),
                      const Text('No se ha podido cargar la página del club.'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _retryClub,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return _content(context, snapshot.data!);
          },
        ),
      );

  Widget _content(BuildContext context, Club club) {
    return FutureBuilder<(List<ClubEvent>, List<Post>)>(
      future: Future.wait([_events, _posts]).then((values) => (values[0] as List<ClubEvent>, values[1] as List<Post>)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data?.$1 ?? const <ClubEvent>[];
        final posts = snapshot.data?.$2 ?? const <Post>[];
        return _contentBody(context, club, events, posts, snapshot.hasError);
      },
    );
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Widget _contentBody(
    BuildContext context,
    Club club,
    List<ClubEvent> events,
    List<Post> posts,
    bool contentError,
  ) {
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
          if (contentError)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Center(
                child: Column(
                  children: [
                    const Text('No se ha podido cargar la actualidad del club.'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _retryContent,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar actualidad'),
                    ),
                  ],
                ),
              ),
            ),
          if (!contentError && (events.isNotEmpty || posts.isNotEmpty))
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actualidad',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 760 ? 2 : 1;
                          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (events.isNotEmpty)
                                _LatestCard(
                                  width: width,
                                  icon: Icons.event_outlined,
                                  title: 'Próximo evento',
                                  headline: events.first.title,
                                  detail: _formatDate(events.first.startAt),
                                  onTap: () => context.go('/club/${widget.clubSlug}/events'),
                                ),
                              if (posts.isNotEmpty)
                                _LatestCard(
                                  width: width,
                                  icon: Icons.article_outlined,
                                  title: 'Última noticia',
                                  headline: posts.first.title,
                                  detail: posts.first.publishedAt == null ? '' : _formatDate(posts.first.publishedAt!),
                                  onTap: () => context.go('/club/${widget.clubSlug}/news'),
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

class _LatestCard extends StatelessWidget {
  const _LatestCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.headline,
    required this.detail,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String headline;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Card(
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.all(18),
            leading: CircleAvatar(child: Icon(icon)),
            title: Text(title),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                detail.isEmpty ? headline : '$headline\n$detail',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ),
        ),
      );
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
