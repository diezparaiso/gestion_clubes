// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): AdSense espera consentimiento y permite reiniciar su estado local.
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

import 'ads_config.dart';
import 'ads_consent_service.dart';

class AdsService {
  const AdsService._();

  static bool _loaded = false;

  static void initialize() {
    if (!kIsWeb || !AdsConfig.enabled || !AdsConsentService.canRequestAds || _loaded) {
      return;
    }

    final existing = html.document.querySelector(
      'script[data-gestion-clubes-adsense="true"]',
    );
    if (existing != null) {
      _loaded = true;
      return;
    }

    final script = html.ScriptElement()
      ..async = true
      ..crossOrigin = 'anonymous'
      ..src =
          'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=\${AdsConfig.publisherId}'
      ..setAttribute('data-gestion-clubes-adsense', 'true');

    html.document.head?.append(script);
    _loaded = true;
  }

  static void reset() {
    _loaded = false;
  }
}
