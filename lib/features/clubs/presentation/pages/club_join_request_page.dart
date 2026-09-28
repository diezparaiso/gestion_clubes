import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): nueva solicitud pública de incorporación de clubes.\n/// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): añade tipo de entidad, web y aceptación de privacidad.\n/// MODIFICADO POR GPT-5.6 LUNA (2026-09-28): añade navegación de retorno a la landing pública.
/// Esta primera fase es frontend-only: no persiste datos ni toca Supabase remoto.
class ClubJoinRequestPage extends StatefulWidget {
  const ClubJoinRequestPage({super.key});

  @override
  State<ClubJoinRequestPage> createState() => _ClubJoinRequestPageState();
}

class _ClubJoinRequestPageState extends State<ClubJoinRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _clubName = TextEditingController();
  final _taxId = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _website = TextEditingController();
  String _clubType = 'Club deportivo';
  bool _privacyAccepted = false;
  final _contactName = TextEditingController();
  final _contactEmail = TextEditingController();
  final _contactPhone = TextEditingController();
  final _notes = TextEditingController();
  final Set<String> _interests = <String>{};
  bool _submitted = false;

  @override
  void dispose() {
    for (final controller in [
      _clubName,
      _taxId,
      _city,
      _province,
      _website,
      _contactName,
      _contactEmail,
      _contactPhone,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes aceptar la información de privacidad para continuar.')));
      return;
    }
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incorporar mi club'),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Plataforma'),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Acceder'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: _submitted ? _SuccessView(onBack: () => context.go('/')) : _buildForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solicita la incorporación de tu club',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Déjanos los datos básicos y el equipo de la plataforma se pondrá en contacto contigo para revisar el alta.',
          ),
          const SizedBox(height: 24),
          _section(
            context,
            title: 'Datos del club',
            icon: Icons.sports_soccer_outlined,
            children: [
              _field(_clubName, 'Nombre del club', required: true),
              _field(_taxId, 'CIF / NIF', required: true),
              _responsiveFields([
                _field(_city, 'Localidad', required: true),
                _field(_province, 'Provincia', required: true),
              ]),
              DropdownButtonFormField<String>(
                value: _clubType,
                decoration: const InputDecoration(labelText: 'Tipo de entidad'),
                items: const [
                  DropdownMenuItem(value: 'Club deportivo', child: Text('Club deportivo')),
                  DropdownMenuItem(value: 'Escuela deportiva', child: Text('Escuela deportiva')),
                  DropdownMenuItem(value: 'Asociación deportiva', child: Text('Asociación deportiva')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (value) => setState(() => _clubType = value ?? _clubType),
              ),
              const SizedBox(height: 16),
              _field(_website, 'Web del club (opcional)'),
            ],
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'Persona de contacto',
            icon: Icons.person_outline,
            children: [
              _field(_contactName, 'Nombre y apellidos', required: true),
              _responsiveFields([
                _field(_contactEmail, 'Email', required: true, email: true),
                _field(_contactPhone, 'Teléfono', required: true),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: '¿Qué quieres utilizar?',
            icon: Icons.tune_outlined,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Gestión del club',
                  'Socios',
                  'Rifas',
                  'Porras',
                  'Pagos',
                  'Patrocinadores',
                  'Web pública',
                ].map((label) {
                  final selected = _interests.contains(label);
                  return FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (value) => setState(() {
                      value ? _interests.add(label) : _interests.remove(label);
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _section(
            context,
            title: 'Observaciones',
            icon: Icons.notes_outlined,
            children: [
              TextFormField(
                controller: _notes,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Cuéntanos brevemente qué necesitas',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _privacyAccepted,
            onChanged: (value) => setState(() => _privacyAccepted = value ?? false),
            title: const Text('He leído la información de privacidad y acepto el tratamiento de los datos de contacto para gestionar esta solicitud.'),
            subtitle: TextButton(
              onPressed: () => context.go('/privacy'),
              child: const Align(alignment: Alignment.centerLeft, child: Text('Consultar política de privacidad')),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No introduzcas datos bancarios en esta solicitud. Cuando el club necesite cobrar mediante la plataforma, la configuración financiera se realizará posteriormente mediante Stripe Connect. La plataforma no debe almacenar el IBAN del club.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Enviar solicitud'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ya tengo una cuenta'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context,
      {required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _responsiveFields(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(children: [
            for (final field in fields) ...[field, const SizedBox(height: 16)],
          ]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              Expanded(child: fields[i]),
              if (i < fields.length - 1) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _field(TextEditingController controller, String label,
      {bool required = false, bool email = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
                if (email && !value.contains('@')) return 'Introduce un email válido';
                return null;
              }
            : null,
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 64),
            const SizedBox(height: 20),
            Text('Solicitud preparada',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text(
              'La pantalla de solicitud ya está preparada. En esta fase de desarrollo no se envían ni almacenan datos todavía: la conexión con el sistema de soporte se incorporará en la siguiente fase.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onBack, child: const Text('Volver al acceso')),
          ],
        ),
      ),
    );
  }
}
