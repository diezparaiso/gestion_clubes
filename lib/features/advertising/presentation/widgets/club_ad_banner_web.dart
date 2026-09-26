// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): banner AdSense real para Flutter Web.
import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import '../../../../core/config/ads_config.dart';

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
        ..setAttribute('data-full-width-responsive', 'true');

      wrapper.append(ad);

      Timer(const Duration(milliseconds: 300), () {
        try {
          final queue = html.document
              .querySelector('body')
              ?.getAttribute('data-adsense-ready');
          if (queue != 'true') return;
          // El script global de AdSense detecta y procesa el bloque.
        } catch (_) {
          // El anuncio nunca debe romper la aplicación.
        }
      });

      return wrapper;
    });
    _registered = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!AdsConfig.enabled) return const SizedBox.shrink();
    _register();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
