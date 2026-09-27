// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): evita solicitudes AdSense sin consentimiento y usa anuncios no personalizados de forma provisional.
import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import '../../../../core/config/ads_config.dart';
import '../../../../core/config/ads_consent_service.dart';
import '../../../../core/config/ads_service.dart';
import 'ads_consent_banner.dart';

@JS('adsbygoogle.push')
external void _pushAd(JSObject options);

class ClubAdBanner extends StatelessWidget {
  const ClubAdBanner({super.key, this.height = 60});

  final double height;

  static bool _registered = false;
  static const _viewType = 'gestion-clubes-adsense-banner';

  static void _register() {
    if (_registered || !AdsConfig.enabled) return;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      final wrapper = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center';

      final ad = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..setAttribute('style', 'display:block;width:100%;min-height:50px;')
        ..setAttribute('data-ad-client', AdsConfig.publisherId)
        ..setAttribute('data-ad-slot', AdsConfig.adSlot)
        ..setAttribute('data-ad-format', 'auto')
        ..setAttribute('data-full-width-responsive', 'true')
        ..setAttribute('data-ad-personalized-ads', 'false');

      wrapper.append(ad);

      var attempts = 0;
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        attempts++;
        try {
          _pushAd(JSObject());
          timer.cancel();
        } catch (_) {
          if (attempts >= 10) timer.cancel();
        }
      });

      return wrapper;
    });
    _registered = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!AdsConfig.enabled) return const SizedBox.shrink();

    if (!AdsConsentService.canRequestAds) {
      return const AdsConsentBanner();
    }

    AdsService.initialize();
    _register();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
