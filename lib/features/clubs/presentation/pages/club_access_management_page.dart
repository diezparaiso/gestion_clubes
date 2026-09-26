import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/auth_controller.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): módulo funcional de gestión de accesos del club.

class ClubAccessManagementPage extends ConsumerStatefulWidget {
  const ClubAccessManagementPage({super.key});
  @override
  ConsumerState<ClubAccessManagementPage> createState() => _ClubAccessManagementPageState();
}

class _ClubAccessManagementPageState extends ConsumerState<ClubAccessManagementPage> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _members = [];
  String? _error;

  static const _roles = <String, String>{
    'club_president': 'Presidente', 'club_treasurer': 'Tesorero/a', 'club_secretary': 'Secretario/a',
    'team_manager': 'Delegado/a', 'coach': 'Entrenador/a', 'staff': 'Personal', 'member': 'Socio/a',
    'parent_guardian': 'Padre/madre/tutor', 'player': 'Jugador/a', 'follower': 'Seguidor/a',
  };

  String get _clubId => ref.read(authControllerProvider).clubId!;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await Supabase.instance.client.from('club_memberships')
          .select('profile_id, role, is_active, profiles!inner(first_name, last_name, email)')
          .eq('club_id', _clubId).eq('is_active', true).order('created_at');
      if (!mounted) return;
      setState(() { _members = List<Map<String, dynamic>>.from(rows); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'No se han podido cargar los accesos.'; });
    }
  }

  Future<void> _createUser() async {
    final first = TextEditingController(), last = TextEditingController(), email = TextEditingController(), password = TextEditingController();
    var role = 'member';
    final formKey = GlobalKey<FormState>();
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Dar de alta usuario'),
          content: SizedBox(width: 520, child: Form(
            key: formKey,
            child: SingleChildScrollView(child: Column(children: [
              TextFormField(controller: first, decoration: const InputDecoration(labelText: 'Nombre'), validator: _required),
              TextFormField(controller: last, decoration: const InputDecoration(labelText: 'Apellidos'), validator: _required),
              TextFormField(controller: email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || !v.contains('@') ? 'Email no válido' : null),
              TextFormField(controller: password, decoration: const InputDecoration(labelText: 'Contraseña inicial'), obscureText: true, validator: (v) => v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role, decoration: const InputDecoration(labelText: 'Rol'),
                items: _roles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setDialogState(() => role = v ?? role),
              ),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerLeft, child: Text('La persona deberá cambiar esta contraseña desde su perfil.')),
            ]))),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(dialogContext, {
                'firstName': first.text.trim(), 'lastName': last.text.trim(), 'email': email.text.trim().toLowerCase(),
                'password': password.text, 'role': role,
              });
            }, child: const Text('Crear acceso')),
          ],
        ),
      ),
    );
    first.dispose(); last.dispose(); email.dispose(); password.dispose();
    if (data == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.functions.invoke('manage-club-user', body: {'clubId': _clubId, ...data});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario creado y acceso asignado.')));
      await _load();
    } on FunctionException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.reasonPhrase ?? 'No se ha podido crear el usuario.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se ha podido crear el usuario.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeRole(Map<String, dynamic> member) async {
    var role = member['role'] as String;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar rol'),
        content: DropdownButtonFormField<String>(
          value: role, items: _roles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => role = v ?? role,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, role), child: const Text('Guardar')),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    try {
      final result = await Supabase.instance.client.rpc('change_member_role', params: {'p_club_id': _clubId, 'p_profile_id': member['profile_id'], 'p_role': selected});
      final row = (result as List).first as Map;
      if (row['success'] != true) throw Exception(row['message']);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol actualizado.'))); await _load(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se ha podido cambiar el rol: $e')));
    }
  }

  Future<void> _revoke(Map<String, dynamic> member) async {
    final profile = member['profiles'] as Map<String, dynamic>;
    final name = (profile['first_name'] ?? '').toString() + ' ' + (profile['last_name'] ?? '').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revocar acceso'),
        content: Text('¿Quieres anular el acceso de $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Revocar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final result = await Supabase.instance.client.rpc('revoke_member_access', params: {'p_club_id': _clubId, 'p_profile_id': member['profile_id']});
      final row = (result as List).first as Map;
      if (row['success'] != true) throw Exception(row['message']);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acceso revocado.'))); await _load(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se ha podido revocar: $e')));
    }
  }

  static String? _required(String? value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authControllerProvider).role;
    if (role != 'club_president' && role != 'club_secretary') return const Scaffold(body: Center(child: Text('No tienes permiso para gestionar accesos.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios y permisos')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _saving ? null : _createUser, icon: const Icon(Icons.person_add_alt_1), label: const Text('Dar de alta')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Text(_error!)) :
        RefreshIndicator(onRefresh: _load, child: ListView(children: [
          Text('Accesos del club', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Asigna roles y revoca accesos. Los permisos de cada rol se aplican automáticamente.'),
          const SizedBox(height: 20),
          ..._members.map((member) {
            final profile = member['profiles'] as Map<String, dynamic>;
            final name = (profile['first_name'] ?? '').toString() + ' ' + (profile['last_name'] ?? '').toString();
            final email = (profile['email'] ?? '').toString();
            final memberRole = member['role'] as String;
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(name.trim().isEmpty ? email : name.trim()),
              subtitle: Text(email + '\n' + (_roles[memberRole] ?? memberRole)), isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) { if (value == 'role') _changeRole(member); if (value == 'revoke') _revoke(member); },
                itemBuilder: (_) => const [PopupMenuItem(value: 'role', child: Text('Cambiar rol')), PopupMenuItem(value: 'revoke', child: Text('Revocar acceso'))],
              ),
            ));
          }),
        ])),
      ),
    );
  }
}
