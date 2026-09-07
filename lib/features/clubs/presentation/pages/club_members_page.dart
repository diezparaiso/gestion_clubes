import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/club_member_repository.dart';
import '../../domain/entities/club_member.dart';

class ClubMembersPage extends ConsumerWidget {
  const ClubMembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubId = ref.watch(authControllerProvider).clubId;

    if (clubId == null) {
      return const Scaffold(
        body: Center(child: Text('No hay un club seleccionado.')),
      );
    }

    final membersAsync = ref.watch(clubMembersProvider(clubId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miembros del Club'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invitar miembro',
            onPressed: () => _showInviteDialog(context, ref, clubId),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (members) => members.isEmpty
            ? const Center(child: Text('No hay miembros.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _MemberCard(
                  member: members[index],
                  clubId: clubId,
                  onChanged: () {
                    ref.invalidate(clubMembersProvider(clubId));
                    ref.invalidate(activeClubMembersProvider(clubId));
                  },
                ),
              ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref, String clubId) {
    showDialog(
      context: context,
      builder: (_) => _InviteMemberDialog(clubId: clubId),
    ).then((_) {
      ref.invalidate(clubMembersProvider(clubId));
      ref.invalidate(activeClubMembersProvider(clubId));
    });
  }
}

class _MemberCard extends ConsumerWidget {
  final ClubMember member;
  final String clubId;
  final VoidCallback onChanged;

  const _MemberCard({
    required this.member,
    required this.clubId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          child: Text(
            member.displayName.isNotEmpty
                ? member.displayName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(
          member.displayName.isNotEmpty ? member.displayName : 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.email ?? 'Sin email'),
            const SizedBox(height: 4),
            Chip(
              label: Text(_roleLabel(member.role)),
              backgroundColor: _roleColor(member.role),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            if (!member.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Acceso revocado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (member.isActive)
              PopupMenuItem(
                child: const Text('Cambiar rol'),
                onTap: () => _showChangeRoleDialog(context, ref),
              ),
            if (member.isActive)
              PopupMenuItem(
                child: const Text('Revocar acceso'),
                onTap: () => _showRevokeDialog(context, ref),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ChangeRoleDialog(
        member: member,
        clubId: clubId,
        onSuccess: onChanged,
      ),
    );
  }

  void _showRevokeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revocar acceso'),
        content: Text(
          '¿Estás seguro de que deseas revocar acceso a ${member.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(clubMemberRepositoryProvider)
                    .revokeClubMemberAccess(clubId, member.profileId);
                onChanged();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Acceso revocado')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'club_president':
        return Colors.red;
      case 'club_treasurer':
        return Colors.green;
      case 'club_secretary':
        return Colors.blue;
      case 'coach':
        return Colors.orange;
      case 'staff':
        return Colors.purple;
      case 'player':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _ChangeRoleDialog extends ConsumerStatefulWidget {
  final ClubMember member;
  final String clubId;
  final VoidCallback onSuccess;

  const _ChangeRoleDialog({
    required this.member,
    required this.clubId,
    required this.onSuccess,
  });

  @override
  ConsumerState<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends ConsumerState<_ChangeRoleDialog> {
  late String _selectedRole = widget.member.role;
  bool _loading = false;

  static const _roles = [
    'club_president',
    'club_treasurer',
    'club_secretary',
    'team_manager',
    'coach',
    'staff',
    'member',
    'player',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar rol'),
      content: DropdownButton<String>(
        isExpanded: true,
        value: _selectedRole,
        items: _roles
            .map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(
                    role
                        .replaceAll('_', ' ')
                        .split(' ')
                        .map((w) => w[0].toUpperCase() + w.substring(1))
                        .join(' '),
                  ),
                ))
            .toList(),
        onChanged: (value) => setState(() => _selectedRole = value ?? _selectedRole),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    await ref
                        .read(clubMemberRepositoryProvider)
                        .changeClubMemberRole(
                          widget.clubId,
                          widget.member.profileId,
                          _selectedRole,
                        );
                    widget.onSuccess();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rol actualizado')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cambiar'),
        ),
      ],
    );
  }
}

class _InviteMemberDialog extends ConsumerStatefulWidget {
  final String clubId;

  const _InviteMemberDialog({required this.clubId});

  @override
  ConsumerState<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<_InviteMemberDialog> {
  final _emailController = TextEditingController();
  String _selectedRole = 'member';
  bool _loading = false;

  static const _roles = [
    'club_president',
    'club_treasurer',
    'club_secretary',
    'team_manager',
    'coach',
    'staff',
    'member',
    'player',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invitar miembro'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'usuario@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedRole,
            items: _roles
                .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(
                        role
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((w) => w[0].toUpperCase() + w.substring(1))
                            .join(' '),
                      ),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedRole = value ?? _selectedRole),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  if (_emailController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Introduce un email')),
                    );
                    return;
                  }

                  setState(() => _loading = true);
                  try {
                    await ref
                        .read(clubMemberRepositoryProvider)
                        .inviteClubMember(
                          widget.clubId,
                          _emailController.text,
                          _selectedRole,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitación enviada')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Invitar'),
        ),
      ],
    );
  }
}