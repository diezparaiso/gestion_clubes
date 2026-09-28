import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';
import '../../data/repositories/sponsor_repository.dart';
import '../../domain/entities/sponsor.dart';

class SponsorsPage extends ConsumerWidget {
  const SponsorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubId = ref.watch(authControllerProvider).clubId;

    if (clubId == null) {
      return const Scaffold(
        body: Center(child: Text('No hay un club seleccionado.')),
      );
    }

    final sponsorsAsync = ref.watch(clubSponsorsProvider(clubId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrocinadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.business_outlined),
            tooltip: 'Nuevo patrocinador',
            onPressed: () => _showCreateDialog(context, ref, clubId),
          ),
        ],
      ),
      body: sponsorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (sponsors) => sponsors.isEmpty
            ? const Center(
                child: Text('No hay patrocinadores. ¡Agrega uno para generar ingresos!'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sponsors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _SponsorCard(
                  sponsor: sponsors[index],
                  clubId: clubId,
                  onChanged: () {
                    ref.invalidate(clubSponsorsProvider(clubId));
                    ref.invalidate(activeSponsorsProvider(clubId));
                  },
                ),
              ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, String clubId) {
    showDialog(
      context: context,
      builder: (_) => _SponsorFormDialog(clubId: clubId),
    ).then((_) {
      ref.invalidate(clubSponsorsProvider(clubId));
      ref.invalidate(activeSponsorsProvider(clubId));
    });
  }
}

class _SponsorCard extends ConsumerWidget {
  final Sponsor sponsor;
  final String clubId;
  final VoidCallback onChanged;

  const _SponsorCard({
    required this.sponsor,
    required this.clubId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusColor(sponsor.status),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        sponsor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(_statusLabel(sponsor.status)),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _statusColor(sponsor.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.euro_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${sponsor.annualAmount.toStringAsFixed(2)} €/año',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${sponsor.contractStartDate.day}/${sponsor.contractStartDate.month} - '
                        '${sponsor.contractEndDate.day}/${sponsor.contractEndDate.month}/${sponsor.contractEndDate.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if (sponsor.isExpired || sponsor.isUpcoming) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: sponsor.isExpired
                          ? Colors.red.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sponsor.isExpired
                          ? 'Patrocinio vencido'
                          : 'Patrocinio próximo',
                      style: TextStyle(
                        fontSize: 12,
                        color: sponsor.isExpired ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(
                    sponsor.daysRemaining,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (sponsor.contactEmail != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Contacto: ${sponsor.contactEmail}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (sponsor.benefits != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Beneficios: ${sponsor.benefits}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showEditDialog(context, ref),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _togglePublic(ref),
                      icon: Icon(
                        sponsor.isPublic
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      label: Text(sponsor.isPublic ? 'Público' : 'Privado'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _SponsorFormDialog(
        clubId: clubId,
        sponsor: sponsor,
      ),
    ).then((_) => onChanged());
  }

  Future<void> _togglePublic(WidgetRef ref) async {
    try {
      await ref.read(sponsorRepositoryProvider).updateSponsor(
            sponsorId: sponsor.id,
            name: sponsor.name,
            website: sponsor.website,
            contactEmail: sponsor.contactEmail,
            contactPhone: sponsor.contactPhone,
            annualAmount: sponsor.annualAmount,
            benefits: sponsor.benefits,
            status: sponsor.status,
            isPublic: !sponsor.isPublic,
          );
      onChanged();
    } catch (e) {
      // Error manejado silenciosamente
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'pending':
        return 'Pendiente';
      case 'expired':
        return 'Vencido';
      case 'cancelled':
        return 'Cancelado';
      case 'paused':
        return 'Pausado';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'paused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _SponsorFormDialog extends ConsumerStatefulWidget {
  final String clubId;
  final Sponsor? sponsor;

  const _SponsorFormDialog({
    required this.clubId,
    this.sponsor,
  });

  @override
  ConsumerState<_SponsorFormDialog> createState() => _SponsorFormDialogState();
}

class _SponsorFormDialogState extends ConsumerState<_SponsorFormDialog> {
  late final TextEditingController nameController;
  late final TextEditingController websiteController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController amountController;
  late final TextEditingController benefitsController;
  late DateTime startDate;
  late DateTime endDate;
  late String selectedStatus;
  late bool isPublic;
  bool isLoading = false;

  static const statuses = ['active', 'pending', 'expired', 'cancelled', 'paused'];

  @override
  void initState() {
    super.initState();
    final sponsor = widget.sponsor;
    if (sponsor != null) {
      nameController = TextEditingController(text: sponsor.name);
      websiteController = TextEditingController(text: sponsor.website ?? '');
      emailController = TextEditingController(text: sponsor.contactEmail ?? '');
      phoneController = TextEditingController(text: sponsor.contactPhone ?? '');
      amountController =
          TextEditingController(text: sponsor.annualAmount.toString());
      benefitsController = TextEditingController(text: sponsor.benefits ?? '');
      startDate = sponsor.contractStartDate;
      endDate = sponsor.contractEndDate;
      selectedStatus = sponsor.status;
      isPublic = sponsor.isPublic;
    } else {
      nameController = TextEditingController();
      websiteController = TextEditingController();
      emailController = TextEditingController();
      phoneController = TextEditingController();
      amountController = TextEditingController();
      benefitsController = TextEditingController();
      startDate = DateTime.now();
      endDate = DateTime.now().add(const Duration(days: 365));
      selectedStatus = 'pending';
      isPublic = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    websiteController.dispose();
    emailController.dispose();
    phoneController.dispose();
    amountController.dispose();
    benefitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.sponsor == null
          ? 'Nuevo Patrocinador'
          : 'Editar Patrocinador'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: websiteController,
              decoration: const InputDecoration(labelText: 'Sitio web'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email de contacto'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monto anual (€)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: benefitsController,
              decoration: const InputDecoration(labelText: 'Beneficios'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2050),
                      );
                      if (date != null && mounted) {
                        setState(() => startDate = date);
                      }
                    },
                    child: Text(
                      'Inicio: ${startDate.day}/${startDate.month}/${startDate.year}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2050),
                      );
                      if (date != null && mounted) {
                        setState(() => endDate = date);
                      }
                    },
                    child: Text(
                      'Fin: ${endDate.day}/${endDate.month}/${endDate.year}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedStatus,
              items: statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) => setState(() => selectedStatus = value ?? selectedStatus),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Visible en sitio público'),
              value: isPublic,
              onChanged: (value) =>
                  setState(() => isPublic = value ?? isPublic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _handleSave,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }

    setState(() => isLoading = true);

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (widget.sponsor == null) {
        await ref.read(sponsorRepositoryProvider).createSponsor(
              clubId: widget.clubId,
              name: nameController.text,
              website: websiteController.text.isEmpty ? null : websiteController.text,
              contactEmail:
                  emailController.text.isEmpty ? null : emailController.text,
              contactPhone: phoneController.text.isEmpty ? null : phoneController.text,
              contractStartDate: startDate,
              contractEndDate: endDate,
              annualAmount: double.parse(amountController.text),
              benefits:
                  benefitsController.text.isEmpty ? null : benefitsController.text,
              isPublic: isPublic,
            );
      } else {
        await ref.read(sponsorRepositoryProvider).updateSponsor(
              sponsorId: widget.sponsor!.id,
              name: nameController.text,
              website: websiteController.text.isEmpty ? null : websiteController.text,
              contactEmail:
                  emailController.text.isEmpty ? null : emailController.text,
              contactPhone: phoneController.text.isEmpty ? null : phoneController.text,
              annualAmount: double.parse(amountController.text),
              benefits:
                  benefitsController.text.isEmpty ? null : benefitsController.text,
              status: selectedStatus,
              isPublic: isPublic,
            );
      }

      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(widget.sponsor == null
                ? 'Patrocinador creado'
                : 'Patrocinador actualizado'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}