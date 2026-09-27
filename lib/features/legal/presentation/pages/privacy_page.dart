// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): añade información pública sobre privacidad, cookies y publicidad.
import 'package:flutter/material.dart';

import '../../../../core/config/ads_consent_service.dart';
import '../../../../core/config/ads_service.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  void _resetConsent() {
    AdsConsentService.clearDecision();
    AdsService.reset();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final decision = AdsConsentService.decision;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y cookies')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Privacidad y publicidad', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'Esta página informa de forma resumida sobre el uso de almacenamiento local y publicidad en la aplicación. '
            'Debe completarse con el texto jurídico definitivo antes de publicar el servicio en producción.',
          ),
          const SizedBox(height: 20),
          const Text('Publicidad', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'La aplicación puede mostrar publicidad mediante Google AdSense en la versión web. '
            'La configuración actual no solicita anuncios hasta que existe una decisión explícita del usuario. '
            'La configuración provisional usa anuncios no personalizados; para publicidad personalizada en las regiones donde sea necesario deberá configurarse una CMP certificada y la política correspondiente.',
          ),
          const SizedBox(height: 20),
          const Text('Almacenamiento local', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Guardamos en el navegador una decisión básica sobre publicidad (aceptada o rechazada) para no volver a mostrar el aviso en cada visita. '
            'La aplicación no utiliza esta preferencia como sustituto de una política de privacidad o de una CMP certificada.',
          ),
          const SizedBox(height: 20),
          Text(
            decision == null
                ? 'No has elegido una preferencia publicitaria.'
                : decision
                    ? 'Publicidad: aceptada.'
                    : 'Publicidad: rechazada.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: decision == null ? null : _resetConsent,
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('Cambiar decisión sobre publicidad'),
          ),
        ],
      ),
    );
  }
}
