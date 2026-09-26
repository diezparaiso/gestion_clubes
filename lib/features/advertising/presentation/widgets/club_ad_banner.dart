// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): banda publicitaria global para Flutter Web.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/config/ads_config.dart';

class ClubAdBanner extends StatelessWidget {
  const ClubAdBanner({
    super.key,
    this.height = 52,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !AdsConfig.enabled) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: const Center(
          child: Text(
            'Publicidad',
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }
}
