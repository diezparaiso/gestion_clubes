// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): aviso previo a la solicitud de publicidad.
import 'package:flutter/material.dart';

import '../../../../core/config/ads_consent_service.dart';
import '../../../../core/config/ads_service.dart';

class AdsConsentBanner extends StatefulWidget {
  const AdsConsentBanner({super.key});

  @override
  State<AdsConsentBanner> createState() => _AdsConsentBannerState();
}

class _AdsConsentBannerState extends State<AdsConsentBanner> {
  @override
  Widget build(BuildContext context) {
    if (AdsConsentService.decision != null) return const SizedBox.shrink();

    return Material(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Usamos publicidad para ayudar a mantener el servicio. '
                'Puedes aceptar o rechazar los anuncios.',
              ),
            ),
            TextButton(
              onPressed: () => setState(() => AdsConsentService.setDecision(false)),
              child: const Text('Rechazar'),
            ),
            FilledButton(
              onPressed: () {
                AdsConsentService.setDecision(true);
                AdsService.initialize();
                setState(() {});
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }
}
