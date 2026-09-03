import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/member_repository.dart';
import '../../domain/entities/member.dart';

final membersProvider = FutureProvider<List<Member>>((ref) {
  final clubId = ref.watch(authControllerProvider).clubId;
  if (clubId == null) return Future.value(const []);
  return ref.watch(memberRepositoryProvider).listMembers(clubId);
});

class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key});

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Socios')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(membersProvider.future),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Directorio de socios', style: Theme.of(context).textTheme.headlineMedium)),
              FilledButton.icon(onPressed: () => _showCreateMemberDialog(context), icon: const Icon(Icons.person_add_alt_1), label: const Text('Nuevo socio')),
            ]),
            const SizedBox(height: 8),
            const Text('Consulta y administra las personas vinculadas al club.'),
            const SizedBox(height: 24),
            TextField(controller: _searchController, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Buscar por nombre, email o número', prefixIcon: Icon(Icons.search))),
            const SizedBox(height: 16),
            Expanded(child: members.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('No se ha podido cargar el listado.')),
              data: (items) {
                final query = _searchController.text.toLowerCase();
                final filtered = items.where((member) => member.name.toLowerCase().contains(query) || member.email.toLowerCase().contains(query) || member.memberNumber.toString().contains(query)).toList();
                if (filtered.isEmpty) return const Center(child: Text('No hay socios que coincidan con la búsqueda.'));
                return Card(child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) => _MemberTile(member: filtered[index]),
                ));
              },
            )),
          ]),
        ),
      ),
    );
  }

  Future<void> _showCreateMemberDialog(BuildContext context) async {
    final result = await showDialog<bool>(context: context, builder: (context) => const _CreateMemberDialog());
    if (result == true && mounted) ref.invalidate(membersProvider);
  }
}

class _CreateMemberDialog extends ConsumerStatefulWidget {
  const _CreateMemberDialog();

  @override
  ConsumerState<_CreateMemberDialog> createState() => _CreateMemberDialogState();
}

class _CreateMemberDialogState extends ConsumerState<_CreateMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _numberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    setState(() { _isSaving = true; _errorMessage = null; });
    try {
      await ref.read(memberRepositoryProvider).createMember(
        clubId: clubId,
        memberNumber: int.parse(_numberController.text),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      setState(() { _isSaving = false; _errorMessage = error.message.contains('duplicate') ? 'Ese número de socio ya está asignado.' : error.message; });
    } catch (_) {
      setState(() { _isSaving = false; _errorMessage = 'No se ha podido guardar el socio.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo socio'),
      content: SizedBox(width: 420, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: _numberController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Número de socio'), validator: (value) => int.tryParse(value ?? '') == null || int.parse(value!) <= 0 ? 'Introduce un número válido' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'Nombre'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Apellidos'), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email de la cuenta'), validator: (value) => value == null || !value.contains('@') ? 'Introduce un email válido' : null),
        if (_errorMessage != null) ...[const SizedBox(height: 16), Align(alignment: Alignment.centerLeft, child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))],
      ])))),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _isSaving ? null : _save, child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar')),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final color = member.status == MemberStatus.active ? const Color(0xFF168B68) : const Color(0xFFD27A2C);
    return ListTile(
      leading: CircleAvatar(backgroundColor: const Color(0xFFE8EFEC), child: Text(member.memberNumber.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF14213D)))),
      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(member.email),
      trailing: Chip(label: Text(member.status.name == 'active' ? 'Activo' : 'Pendiente'), backgroundColor: color.withValues(alpha: 0.12), side: BorderSide.none, labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
