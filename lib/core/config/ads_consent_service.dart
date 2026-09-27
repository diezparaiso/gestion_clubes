// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): permite consultar, cambiar y retirar la decisión publicitaria web.
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class AdsConsentService {
  const AdsConsentService._();

  static const _storageKey = 'gestion_clubes_ads_consent';

  static bool? get decision {
    if (!kIsWeb) return false;
    final value = html.window.localStorage[_storageKey];
    if (value == 'accepted') return true;
    if (value == 'rejected') return false;
    return null;
  }

  static bool get canRequestAds => decision == true;

  static void setDecision(bool accepted) {
    if (!kIsWeb) return;
    html.window.localStorage[_storageKey] = accepted ? 'accepted' : 'rejected';
  }

  static void clearDecision() {
    if (!kIsWeb) return;
    html.window.localStorage.remove(_storageKey);
  }
}
