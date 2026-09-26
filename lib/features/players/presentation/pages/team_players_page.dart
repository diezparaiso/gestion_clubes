import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Alta/asignación y edición de jugadores.
// Reutiliza cuentas existentes; no crea credenciales ni modifica Stripe.

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/player_repository.dart';
import '../../domain/entities/player.dart';

final teamPlayersProvider = FutureProvider.family<List<Player>, String>((ref, teamId) {
  ref.watch(authControllerProvider);
  return ref.watch(playerRepositoryProvider).listTeamPlayers(teamId);
});

class TeamPlayersPage extends ConsumerStatefulWidget {
  const TeamPlayersPage({required this.teamId, required this.teamName, super.key});

  final String teamId;
  final String teamName;

  @override
  ConsumerState<TeamPlayersPage> createState() => _TeamPlayersPageState();
}

class _TeamPlayersPageState extends ConsumerState<TeamPlayersPage> {
  Future<void> _editPlayer(Player player) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _EditPlayerDialog(teamId: widget.teamId, player: player),
    );
    if (result == true && mounted) {
      ref.invalidate(teamPlayersProvider(widget.teamId));
    }
  }

  Future<void> _createPlayer() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _CreatePlayerDialog(teamId: widget.teamId),
    );
    if (result == true && mounted) {
      ref.invalidate(teamPlayersProvider(widget.teamId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = widget.teamId;
    final teamName = widget.teamName;
    final players = ref.watch(teamPlayersProvider(teamId));
    return Scaffold(
      appBar: AppBar(
        title: Text(teamName),
        actions: [
          IconButton(
            onPressed: () => context.go('/teams/$teamId/staff', extra: teamName),
            tooltip: 'Ver cuerpo técnico',
            icon: const Icon(Icons.sports_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plantilla', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    const Text('Jugadores asignados a este equipo.'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _createPlayer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Nuevo jugador'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: players.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const Center(child: Text('No se ha podido cargar la plantilla.')),
            data: (items) => Card(child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _PlayerTile(
                player: items[index],
                onEdit: () => _editPlayer(items[index]),
              ),
            )),
          )),
        ]),
      ),
    );
  }
}

class _CreatePlayerDialog extends ConsumerStatefulWidget {
  const _CreatePlayerDialog({required this.teamId});

  final String teamId;

  @override
  ConsumerState<_CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends ConsumerState<_CreatePlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _jerseyController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _jerseyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final clubId = ref.read(authControllerProvider).clubId;
      if (clubId == null) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'No hay un club activo en la sesión.';
        });
        return;
      }
      await ref.read(playerRepositoryProvider).createAndAssignPlayer(
        clubId: clubId,
        teamId: widget.teamId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        jerseyNumber: _jerseyController.text.trim().isEmpty
            ? null
            : int.parse(_jerseyController.text.trim()),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = error.message.contains('duplicate')
              ? 'El jugador ya está asignado a este equipo o el dorsal ya está ocupado.'
              : error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'No se ha podido crear el jugador.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo jugador'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'El jugador debe tener una cuenta registrada con ese email.',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Indica el nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Indica los apellidos' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email de la cuenta'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty || !email.contains('@')) return 'Indica un email válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jerseyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dorsal',
                    hintText: 'Opcional',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final number = int.tryParse(value.trim());
                    return number == null || number < 1 || number > 99
                        ? 'Dorsal entre 1 y 99'
                        : null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear y asignar'),
        ),
      ],
    );
  }
}

class _EditPlayerDialog extends ConsumerStatefulWidget {
  const _EditPlayerDialog({required this.teamId, required this.player});

  final String teamId;
  final Player player;

  @override
  ConsumerState<_EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends ConsumerState<_EditPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _jerseyController;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _jerseyController = TextEditingController(
      text: widget.player.jerseyNumber?.toString() ?? '',
    );
    _isActive = widget.player.isActive;
  }

  @override
  void dispose() {
    _jerseyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final clubId = ref.read(authControllerProvider).clubId;
      if (clubId == null) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'No hay un club activo en la sesión.';
        });
        return;
      }
      await ref.read(playerRepositoryProvider).updateTeamPlayer(
        clubId: clubId,
        teamId: widget.teamId,
        playerId: widget.player.id,
        jerseyNumber: _jerseyController.text.trim().isEmpty
            ? null
            : int.parse(_jerseyController.text.trim()),
        isActive: _isActive,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = error.message.contains('duplicate')
              ? 'Ese dorsal ya está asignado.'
              : error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'No se ha podido guardar el jugador.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar jugador'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.player.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jerseyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Dorsal', hintText: 'Opcional'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final number = int.tryParse(value.trim());
                  return number == null || number < 1 || number > 99
                      ? 'Dorsal entre 1 y 99'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jugador activo'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.onEdit});

  final Player player;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE4B363),
        child: Text(player.jerseyNumber?.toString() ?? '-'),
      ),
      title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(player.isActive ? 'Jugador activo' : 'Baja de equipo'),
      trailing: IconButton(
        tooltip: 'Editar jugador',
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined),
      ),
    );
  }
}
