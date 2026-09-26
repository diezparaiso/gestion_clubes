// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): integra banda publicitaria global.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'router.dart';
import '../features/advertising/presentation/widgets/club_ad_banner.dart';

class ClubPlatformApp extends ConsumerWidget {
  const ClubPlatformApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Club Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        return Column(
          children: [
            const ClubAdBanner(height: 60),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
