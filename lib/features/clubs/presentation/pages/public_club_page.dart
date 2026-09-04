import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/club_repository.dart';
import '../../domain/entities/club.dart';

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
        appBar: AppBar(title: const Text('Club Platform')),
        body: FutureBuilder<Club>(
          future: _club,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError || snapshot.data == null) return const Center(child: Text('Este club no está disponible.'));
            return _content(context, snapshot.data!);
          },
        ),
      );

  Widget _content(BuildContext context, Club club) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Text(club.publicName, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Información pública del club, actividades y campañas.'),
              const SizedBox(height: 24),
              _PublicSection(icon: Icons.article_outlined, title: 'Noticias', description: 'Últimas novedades del club.', onTap: () => context.go('/club/${widget.clubSlug}/news')),
              const SizedBox(height: 12),
              _PublicSection(icon: Icons.event_outlined, title: 'Eventos', description: 'Partidos y actividades próximas.', onTap: () => context.go('/club/${widget.clubSlug}/events')),
              const SizedBox(height: 12),
              _PublicSection(icon: Icons.confirmation_number_outlined, title: 'Rifas', description: 'Consulta las campañas públicas del club.', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comparte el enlace de una rifa para abrirla.')))),
            ]),
          ),
      );
}

class _PublicSection extends StatelessWidget {
  const _PublicSection({required this.icon, required this.title, required this.description, required this.onTap});
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, contentPadding: const EdgeInsets.all(18), leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(description), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16)));
}