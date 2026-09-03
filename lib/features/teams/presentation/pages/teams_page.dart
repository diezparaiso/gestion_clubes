import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/team_repository.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/season.dart';

final teamsProvider = FutureProvider<List<Team>>((ref) {
  final clubId = ref.watch(authControllerProvider).clubId;
  if (clubId == null) return Future.value(const []);
  return ref.watch(teamRepositoryProvider).listTeams(clubId);
});

final seasonsProvider = FutureProvider<List<Season>>((ref) {
  final clubId = ref.watch(authControllerProvider).clubId;
  if (clubId == null) return Future.value(const []);
  return ref.watch(teamRepositoryProvider).listSeasons(clubId);
});

class TeamsPage extends ConsumerStatefulWidget {
  const TeamsPage({super.key});

  @override
  ConsumerState<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends ConsumerState<TeamsPage> {
  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Equipos')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(teamsProvider.future),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Equipos y temporadas', style: Theme.of(context).textTheme.headlineMedium)),
              FilledButton.icon(onPressed: () => _showCreateTeamDialog(context), icon: const Icon(Icons.add), label: const Text('Nuevo equipo')),
            ]),
            const SizedBox(height: 8),
            const Text('Organiza las plantillas del club por categoría y temporada.'),
            const SizedBox(height: 24),
            Expanded(child: teams.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Center(child: Text('No se han podido cargar los equipos.')),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('Todavía no hay equipos creados.'))
                  : LayoutBuilder(builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 800 ? 3 : constraints.maxWidth >= 500 ? 2 : 1;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.55),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _TeamCard(team: items[index]),
                      );
                    }),
            )),
          ]),
        ),
      ),
    );
  }

  Future<void> _showCreateTeamDialog(BuildContext context) async {
    final result = await showDialog<bool>(context: context, builder: (_) => const _CreateTeamDialog());
    if (result == true && mounted) {
      ref.invalidate(teamsProvider);
    }
  }
}

class _CreateTeamDialog extends ConsumerStatefulWidget {
  const _CreateTeamDialog();

  @override
  ConsumerState<_CreateTeamDialog> createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends ConsumerState<_CreateTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  Season? _selectedSeason;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedSeason == null) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    setState(() { _isSaving = true; _errorMessage = null; });
    try {
      await ref.read(teamRepositoryProvider).createTeam(clubId: clubId, name: _nameController.text.trim(), category: _categoryController.text.trim(), seasonId: _selectedSeason!.id, seasonName: _selectedSeason!.name);
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      setState(() { _isSaving = false; _errorMessage = error.message.contains('duplicate') ? 'Ya existe un equipo con ese nombre en la temporada.' : error.message; });
    } catch (_) {
      setState(() { _isSaving = false; _errorMessage = 'No se ha podido guardar el equipo.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasons = ref.watch(seasonsProvider);
    return AlertDialog(
      title: const Text('Nuevo equipo'),
      content: SizedBox(width: 420, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre del equipo'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Categoría'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null),
        const SizedBox(height: 12),
        seasons.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => const Align(alignment: Alignment.centerLeft, child: Text('No se han podido cargar las temporadas.')),
          data: (items) => DropdownButtonFormField<Season>(
            initialValue: _selectedSeason,
            decoration: const InputDecoration(labelText: 'Temporada'),
            items: items.map((season) => DropdownMenuItem(value: season, child: Text(season.name))).toList(),
            onChanged: (season) => setState(() => _selectedSeason = season),
            validator: (value) => value == null ? 'Selecciona una temporada' : null,
          ),
        ),
        if (_errorMessage != null) ...[const SizedBox(height: 16), Align(alignment: Alignment.centerLeft, child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))],
      ])))),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _isSaving ? null : _save, child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar')),
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const CircleAvatar(backgroundColor: Color(0xFFE8EFEC), child: Icon(Icons.groups_outlined, color: Color(0xFF168B68))),
        const Spacer(),
        Chip(label: Text(team.isActive ? 'Activo' : 'Inactivo'), backgroundColor: const Color(0xFFE8EFEC), side: BorderSide.none, labelStyle: const TextStyle(color: Color(0xFF168B68), fontWeight: FontWeight.w700)),
      ]),
      const Spacer(),
      Text(team.name, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(team.category),
      const SizedBox(height: 10),
      Row(children: [const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF77838F)), const SizedBox(width: 6), Text(team.seasonName, style: const TextStyle(fontSize: 13))]),
    ])));
  }
}
