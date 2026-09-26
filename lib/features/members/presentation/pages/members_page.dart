import 'package:club_payments/club_payments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Gestión completa de campos existentes en memberships.
// Cobro de cuota con club_payments añadido en sesión posterior.

import '../../../auth/application/auth_controller.dart';
import '../../../finance/data/repositories/finance_repository.dart';
import '../../../finance/domain/entities/financial_transaction.dart';
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
  MemberStatus? _statusFilter;
  MembershipType? _membershipTypeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _statusLabel(MemberStatus status) => switch (status) {
    MemberStatus.active => 'Activo', MemberStatus.pending => 'Pendiente', MemberStatus.expired => 'Caducado', MemberStatus.cancelled => 'Cancelado', MemberStatus.deceased => 'Fallecido', MemberStatus.suspended => 'Suspendido',
  };
  String _membershipTypeLabel(MembershipType type) => switch (type) {
    MembershipType.standard => 'Estándar', MembershipType.youth => 'Juvenil', MembershipType.family => 'Familiar', MembershipType.supporter => 'Simpatizante', MembershipType.other => 'Otro',
  };

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Socios')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(membersProvider.future),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Directorio de socios',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCreateMemberDialog(context),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Nuevo socio'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Consulta y administra las personas vinculadas al club.'),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, email o número',
                  prefixIcon: Icon(Icons.search),
                ),
              )),
                const SizedBox(width: 12),
                DropdownButton<MemberStatus?>(
                  value: _statusFilter,
                  hint: const Text('Estado'),
                  items: [const DropdownMenuItem<MemberStatus?>(value: null, child: Text('Todos los estados')), ...MemberStatus.values.map((status) => DropdownMenuItem<MemberStatus?>(value: status, child: Text(_statusLabel(status))))],
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
                const SizedBox(width: 12),
                DropdownButton<MembershipType?>(
                  value: _membershipTypeFilter,
                  hint: const Text('Tipo'),
                  items: [const DropdownMenuItem<MembershipType?>(value: null, child: Text('Todos los tipos')), ...MembershipType.values.map((type) => DropdownMenuItem<MembershipType?>(value: type, child: Text(_membershipTypeLabel(type))))],
                  onChanged: (value) => setState(() => _membershipTypeFilter = value),
                ),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: members.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      const Center(child: Text('No se ha podido cargar el listado.')),
                  data: (items) {
                    final query = _searchController.text.toLowerCase();
                    final filtered = items.where((member) {
                      final matchesSearch = member.name.toLowerCase().contains(query) || member.email.toLowerCase().contains(query) || member.memberNumber.toString().contains(query);
                      final matchesStatus = _statusFilter == null || member.status == _statusFilter;
                      final matchesType = _membershipTypeFilter == null || member.membershipType == _membershipTypeFilter;
                      return matchesSearch && matchesStatus && matchesType;
                    }).toList();
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No hay socios que coincidan con la búsqueda.'),
                      );
                    }
                    return Card(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, index) => const Divider(height: 1),
                        itemBuilder: (context, index) => _MemberTile(
                          member: filtered[index],
                          onEdit: () => _showEditMemberDialog(context, filtered[index]),
                          onChargeFee: () => _showChargeFeeDialog(context, filtered[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditMemberDialog(BuildContext context, Member member) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _EditMemberDialog(member: member),
    );
    if (result == true && mounted) ref.invalidate(membersProvider);
  }

  Future<void> _showCreateMemberDialog(BuildContext context) async {
    final result =
        await showDialog<bool>(context: context, builder: (context) => const _CreateMemberDialog());
    if (result == true && mounted) ref.invalidate(membersProvider);
  }

  Future<void> _showChargeFeeDialog(BuildContext context, Member member) async {
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    final charged = await showDialog<bool>(
      context: context,
      builder: (context) => _ChargeFeeDialog(member: member, clubId: clubId),
    );
    if (charged == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cuota cobrada a ${member.name}.')),
      );
    }
  }
}

/// Charges a membership fee to [member] using club_payments, and on
/// success records the corresponding movement in Tesorería (Finance).
///
/// Uses [MockPaymentProvider] for now. Once the backend is deployed with
/// real Stripe Connect accounts per club, swap it for:
///   StripePaymentProvider(baseUrl: '<your deployed backend URL>')
/// No other code in this dialog needs to change.
class _ChargeFeeDialog extends ConsumerStatefulWidget {
  const _ChargeFeeDialog({required this.member, required this.clubId});

  final Member member;
  final String clubId;

  @override
  ConsumerState<_ChargeFeeDialog> createState() => _ChargeFeeDialogState();
}

class _ChargeFeeDialogState extends ConsumerState<_ChargeFeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '25,00');
  final _descriptionController = TextEditingController(text: 'Cuota de socio');
  bool _isCharging = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _charge() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isCharging = true;
      _errorMessage = null;
    });

    try {
      final euros = double.parse(_amountController.text.replaceAll(',', '.'));
      final cents = (euros * 100).round();

      final paymentService = PaymentService(provider: MockPaymentProvider());
      final result = await paymentService.createPayment(
        PaymentRequest(
          amount: PaymentAmount(value: cents, currency: 'EUR'),
          description: _descriptionController.text.trim(),
          reference:
              'MEMBERSHIP-${widget.member.id}-${DateTime.now().millisecondsSinceEpoch}',
          clubId: widget.clubId,
          customer: PaymentCustomer(id: widget.member.id),
          metadata: const {'type': 'membership'},
        ),
      );

      if (!result.success) {
        setState(() {
          _isCharging = false;
          _errorMessage = result.errorMessage ?? 'El pago no se ha podido procesar.';
        });
        return;
      }

      await ref.read(financeRepositoryProvider).createTransaction(
            clubId: widget.clubId,
            type: TransactionType.income,
            category: 'membership',
            amount: euros,
            description: '${_descriptionController.text.trim()} - ${widget.member.name}',
          );

      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      setState(() {
        _isCharging = false;
        _errorMessage = 'No se ha podido completar el cobro.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cobrar cuota a ${widget.member.name}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Importe', suffixText: '€'),
                  validator: (value) =>
                      double.tryParse((value ?? '').replaceAll(',', '.')) == null
                          ? 'Introduce un importe válido'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Concepto'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Campo obligatorio' : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCharging ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isCharging ? null : _charge,
          child: _isCharging
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cobrar'),
        ),
      ],
    );
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
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _numberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ref.read(memberRepositoryProvider).createMember(
            clubId: clubId,
            memberNumber: int.parse(_numberController.text),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text,
            postalCode: _postalCodeController.text,
            city: _cityController.text,
            province: _provinceController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      setState(() {
        _isSaving = false;
        _errorMessage = error.message.contains('duplicate')
            ? 'Ese número de socio ya está asignado.'
            : error.message;
      });
    } catch (_) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'No se ha podido guardar el socio.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo socio'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Número de socio'),
                  validator: (value) => int.tryParse(value ?? '') == null || int.parse(value!) <= 0
                      ? 'Introduce un número válido'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email de la cuenta'),
                  validator: (value) =>
                      value == null || !value.contains('@') ? 'Introduce un email válido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Dirección postal'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _postalCodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Código postal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'Localidad'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _provinceController,
                  decoration: const InputDecoration(labelText: 'Provincia'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
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
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _EditMemberDialog extends ConsumerStatefulWidget {
  const _EditMemberDialog({required this.member});

  final Member member;

  @override
  ConsumerState<_EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends ConsumerState<_EditMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _notesController;
  late final TextEditingController _addressController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _cityController;
  late final TextEditingController _provinceController;
  late MemberStatus _status;
  late MembershipType _membershipType;
  late DateTime _joinDate;
  DateTime? _renewalDate;
  DateTime? _leaveDate;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.member.memberNumber.toString());
    _notesController = TextEditingController(text: widget.member.notes ?? '');
    _addressController = TextEditingController(text: widget.member.address ?? '');
    _postalCodeController = TextEditingController(text: widget.member.postalCode ?? '');
    _cityController = TextEditingController(text: widget.member.city ?? '');
    _provinceController = TextEditingController(text: widget.member.province ?? '');
    _status = widget.member.status;
    _membershipType = widget.member.membershipType;
    _joinDate = widget.member.joinDate;
    _renewalDate = widget.member.renewalDate;
    _leaveDate = widget.member.leaveDate;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  String _statusLabel(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return 'Activo';
      case MemberStatus.pending:
        return 'Pendiente';
      case MemberStatus.expired:
        return 'Caducado';
      case MemberStatus.cancelled:
        return 'Cancelado';
      case MemberStatus.suspended:
        return 'Suspendido';
      case MemberStatus.deceased:
        return 'Fallecido';
    }
  }

  String _membershipTypeLabel(MembershipType type) {
    switch (type) {
      case MembershipType.standard:
        return 'Estándar';
      case MembershipType.youth:
        return 'Juvenil';
      case MembershipType.family:
        return 'Familiar';
      case MembershipType.supporter:
        return 'Simpatizante';
      case MembershipType.other:
        return 'Otro';
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<DateTime?> _pickDate(DateTime? current) async {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _selectJoinDate() async {
    final value = await _pickDate(_joinDate);
    if (value != null && mounted) setState(() => _joinDate = value);
  }

  Future<void> _selectRenewalDate() async {
    final value = await _pickDate(_renewalDate);
    if (value != null && mounted) setState(() => _renewalDate = value);
  }

  Future<void> _selectLeaveDate() async {
    final value = await _pickDate(_leaveDate);
    if (value != null && mounted) setState(() => _leaveDate = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clubId = ref.read(authControllerProvider).clubId;
    if (clubId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(memberRepositoryProvider).updateMember(
            clubId: clubId,
            memberId: widget.member.id,
            memberNumber: int.parse(_numberController.text),
            status: _status,
            membershipType: _membershipType,
            joinDate: _joinDate,
            renewalDate: _renewalDate,
            leaveDate: _leaveDate,
            notes: _notesController.text,
            address: _addressController.text,
            postalCode: _postalCodeController.text,
            city: _cityController.text,
            province: _provinceController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = error.message.contains('duplicate')
              ? 'Ese número de socio ya está asignado.'
              : error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'No se ha podido guardar el socio.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar socio'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.member.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(widget.member.email),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Número de socio'),
                  validator: (value) => int.tryParse(value ?? '') == null || int.parse(value!) <= 0
                      ? 'Introduce un número válido'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MemberStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: MemberStatus.values
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabel(status)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MembershipType>(
                  initialValue: _membershipType,
                  decoration: const InputDecoration(labelText: 'Tipo de socio'),
                  items: MembershipType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_membershipTypeLabel(type)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _membershipType = value);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alta'),
                  subtitle: Text(_formatDate(_joinDate)),
                  trailing: IconButton(
                    onPressed: _isSaving ? null : _selectJoinDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Renovación'),
                  subtitle: Text(_renewalDate == null ? 'Sin fecha' : _formatDate(_renewalDate!)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_renewalDate != null)
                        IconButton(
                          onPressed: _isSaving ? null : () => setState(() => _renewalDate = null),
                          icon: const Icon(Icons.clear),
                        ),
                      IconButton(
                        onPressed: _isSaving ? null : _selectRenewalDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Baja'),
                  subtitle: Text(_leaveDate == null ? 'Sin fecha' : _formatDate(_leaveDate!)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_leaveDate != null)
                        IconButton(
                          onPressed: _isSaving ? null : () => setState(() => _leaveDate = null),
                          icon: const Icon(Icons.clear),
                        ),
                      IconButton(
                        onPressed: _isSaving ? null : _selectLeaveDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ],
                  ),
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Dirección postal'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _postalCodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Código postal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'Localidad'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _provinceController,
                  decoration: const InputDecoration(labelText: 'Provincia'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notas'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
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
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onEdit, required this.onChargeFee});

  final Member member;
  final VoidCallback onEdit;
  final VoidCallback onChargeFee;

  String _statusLabel(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return 'Activo';
      case MemberStatus.pending:
        return 'Pendiente';
      case MemberStatus.expired:
        return 'Caducado';
      case MemberStatus.cancelled:
        return 'Cancelado';
      case MemberStatus.suspended:
        return 'Suspendido';
      case MemberStatus.deceased:
        return 'Fallecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = member.status == MemberStatus.active;
    final color = isActive ? const Color(0xFF168B68) : const Color(0xFFD27A2C);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8EFEC),
        child: Text(
          member.memberNumber.toString(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF14213D)),
        ),
      ),
      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(member.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(_statusLabel(member.status)),
            backgroundColor: color.withValues(alpha: 0.12),
            side: BorderSide.none,
            labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          IconButton(
            tooltip: 'Cobrar cuota',
            onPressed: onChargeFee,
            icon: const Icon(Icons.payments_outlined),
          ),
          IconButton(
            tooltip: 'Editar socio',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}