// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): añade escaparate público de patrocinadores.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/repositories/sponsor_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/sponsor.dart';

class PublicSponsorsPage extends StatefulWidget {
  const PublicSponsorsPage({super.key, required this.clubSlug});

  final String clubSlug;

  @override
  State<PublicSponsorsPage> createState() => _PublicSponsorsPageState();
}

class _PublicSponsorsPageState extends State<PublicSponsorsPage> {
  late final Future<List<Sponsor>> _sponsors;

  @override
  void initState() {
    super.initState();
    final client = SupabaseService.isConfigured ? Supabase.instance.client : null;
    _sponsors = SponsorRepository(client).getPublicSponsors(widget.clubSlug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patrocinadores del club')),
      body: FutureBuilder<List<Sponsor>>(
        future: _sponsors,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('No se han podido cargar los patrocinadores.'));
          }
          final sponsors = snapshot.data ?? const <Sponsor>[];
          if (sponsors.isEmpty) {
            return const Center(child: Text('Actualmente no hay patrocinadores publicados.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: sponsors.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _SponsorPublicCard(sponsor: sponsors[index]),
          );
        },
      ),
    );
  }
}

class _SponsorPublicCard extends StatelessWidget {
  const _SponsorPublicCard({required this.sponsor});

  final Sponsor sponsor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          spacing: 24,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sponsor.name, style: Theme.of(context).textTheme.titleLarge),
                if (sponsor.benefits != null && sponsor.benefits!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(sponsor.benefits!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
            if (sponsor.website != null && sponsor.website!.trim().isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(sponsor.website!), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.language_outlined),
                label: const Text('Visitar web'),
              ),
          ],
        ),
      ),
    );
  }
}
