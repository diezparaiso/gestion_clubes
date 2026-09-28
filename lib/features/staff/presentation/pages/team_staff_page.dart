import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Alta, edición y activación del personal usando team_staff existente.
// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): Gestión de personal visible solo con teams_manage.

import '../../../auth/application/auth_controller.dart';
import '../../../dashboard/presentation/widgets/club_navigation_app_bar.dart';
import '../../data/repositories/team_staff_repository.dart';
import '../../domain/entities/team_staff.dart';

final teamStaffProvider = FutureProvider.family<List<TeamStaff>, String>((ref, teamId) {
  ref.watch(authControllerProvider);
  return ref.watch(teamStaffRepositoryProvider).listTeamStaff(teamId);
});

class TeamStaffPage extends ConsumerStatefulWidget {
  const TeamStaffPage({required this.teamId, required this.teamName, super.key});

  final String teamId;
  final String teamName;

  @override
  ConsumerState<TeamStaffPage> createState() => _TeamStaffPageState();
}

class _TeamStaffPageState extends ConsumerState<TeamStaffPage> {
  // MODIFICADO POR GPT-5.6 LUNA (2026-09-28): cierre del flujo Equipos → Personal; filtros, responsive y estados vacíos.
  final _searchController = TextEditingController();
  bool _showInactive = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _newStaff() async {
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    final result = await showDialog<bool>(context: context, builder: (_) => _CreateStaffDialog(clubId: clubId, teamId: widget.teamId));
    if (result == true && mounted) ref.invalidate(teamStaffProvider(widget.teamId));
  }

  Future<void> _editStaff(TeamStaff staff) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _EditStaffDialog(teamId: widget.teamId, staff: staff),
    );
    if (result == true && mounted) ref.invalidate(teamStaffProvider(widget.teamId));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final canManage = ClubRolePermissions.has(auth.role, 'teams_manage');
    final teamId = widget.teamId;
    final teamName = widget.teamName;
    final staff = ref.watch(teamStaffProvider(teamId));
    return Scaffold(
      appBar: ClubNavigationAppBar(title: '$teamName · Personal'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Cuerpo técnico', style: Theme.of(context).textTheme.headlineMedium),
              if (canManage)
                FilledButton.icon(
                  onPressed: _newStaff,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Añadir personal'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Entrenadores y personal asignado a este equipo.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 520),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Buscar persona o cargo',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              FilterChip(
                label: const Text('Mostrar inactivos'),
                selected: _showInactive,
                onSelected: (value) => setState(() => _showInactive = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: staff.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: _StaffLoadError(onRetry: () => ref.invalidate(staffProvider))),
            data: (items) {
              final query = _searchController.text.trim().toLowerCase();
              final filtered = items.where((member) {
                final matchesText = query.isEmpty || member.name.toLowerCase().contains(query) || member.role.toLowerCase().contains(query);
                return matchesText && (_showInactive || member.isActive);
              }).toList();
              if (filtered.isEmpty) {
                return Center(child: Text(items.isEmpty ? 'Todavía no hay personal asignado.' : 'No hay personal que coincida con el filtro.'));
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(teamStaffProvider(teamId).future),
                child: Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = filtered[index];
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFE8EFEC), child: Icon(Icons.sports_outlined, color: Color(0xFF168B68))),
                        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(member.role),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          member.isActive ? const Icon(Icons.check_circle_outline, color: Color(0xFF168B68)) : const Icon(Icons.cancel_outlined, color: Color(0xFF9BA9BC)),
                          if (canManage) IconButton(tooltip: 'Editar personal', onPressed: () => _editStaff(member), icon: const Icon(Icons.edit_outlined)),
                        ]),
                      );
                    },
                  ),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }
}



class _CreateStaffDialog extends ConsumerStatefulWidget {
  const _CreateStaffDialog({required this.clubId, required this.teamId});
  final String clubId;
  final String teamId;
  @override
  ConsumerState<_CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends ConsumerState<_CreateStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _errorMessage = null; });
    try {
      await ref.read(teamStaffRepositoryProvider).createAndAssignStaff(
        clubId: widget.clubId,
        teamId: widget.teamId,
        email: _emailController.text.trim(),
        role: _roleController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      if (mounted) setState(() { _isSaving = false; _errorMessage = error.message.contains('duplicate') ? 'Esa persona ya tiene ese cargo en este equipo.' : error.message; });
    } catch (_) {
      if (mounted) setState(() { _isSaving = false; _errorMessage = 'No se ha podido asignar el personal.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir personal'),
      content: SizedBox(width: 420, child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email de la cuenta'), validator: (value) => value == null || !value.contains('@') ? 'Introduce un email válido' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _roleController, decoration: const InputDecoration(labelText: 'Cargo / función'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null),
        if (_errorMessage != null) ...[const SizedBox(height: 16), Align(alignment: Alignment.centerLeft, child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))],
      ]))),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _isSaving ? null : _save, child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar')),
      ],
    );
  }
}

class _EditStaffDialog extends ConsumerStatefulWidget {
  const _EditStaffDialog({required this.teamId, required this.staff});

  final String teamId;
  final TeamStaff staff;

  @override
  ConsumerState<_EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends ConsumerState<_EditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roleController;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _roleController = TextEditingController(text: widget.staff.role);
    _isActive = widget.staff.isActive;
  }

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _errorMessage = null; });
    try {
      final clubId = ref.read(authControllerProvider).clubId;
      if (clubId == null) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'No hay un club activo en la sesión.';
        });
        return;
      }
      await ref.read(teamStaffRepositoryProvider).updateTeamStaff(
        clubId: clubId,
        teamId: widget.teamId,
        staffId: widget.staff.id,
        role: _roleController.text.trim(),
        isActive: _isActive,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      if (mounted) setState(() { _isSaving = false; _errorMessage = error.message; });
    } catch (_) {
      if (mounted) setState(() { _isSaving = false; _errorMessage = 'No se ha podido guardar el personal.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar personal'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.staff.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(labelText: 'Cargo / función'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Personal activo'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
        ),
      ],
    );
  }
}
