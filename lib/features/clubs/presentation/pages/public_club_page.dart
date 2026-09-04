import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PublicClubPage extends StatelessWidget {
  const PublicClubPage({super.key, required this.clubSlug});
  final String clubSlug;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Club Platform')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Text('Club ${clubSlug.replaceAll('-', ' ')}', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Información pública del club, actividades y campañas.'),
              const SizedBox(height: 24),
              _PublicSection(icon: Icons.article_outlined, title: 'Noticias', description: 'Últimas novedades del club.', onTap: () => context.go('/club/$clubSlug/news')),
              const SizedBox(height: 12),
              _PublicSection(icon: Icons.event_outlined, title: 'Eventos', description: 'Partidos y actividades próximas.', onTap: () => context.go('/club/$clubSlug/events')),
              const SizedBox(height: 12),
              _PublicSection(icon: Icons.confirmation_number_outlined, title: 'Rifas', description: 'Consulta las campañas públicas del club.', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comparte el enlace de una rifa para abrirla.')))),
            ]),
          ),
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