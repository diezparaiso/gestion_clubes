// MODIFICADO POR GPT-5.6 LUNA (2026-09-30): selector global de idioma e integración ES/EN/IT/PT.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'router.dart';
import '../core/i18n/app_localizations.dart';
import '../features/advertising/presentation/widgets/club_ad_banner.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('es'));

class ClubPlatformApp extends ConsumerWidget {
  const ClubPlatformApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Club Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                child: DropdownButton<Locale>(
                  value: locale,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  tooltip: AppLocalizations(locale).t('language'),
                  items: const [
                    DropdownMenuItem(value: Locale('es'), child: Text('🇪🇸 ES')),
                    DropdownMenuItem(value: Locale('en'), child: Text('🇬🇧 EN')),
                    DropdownMenuItem(value: Locale('it'), child: Text('🇮🇹 IT')),
                    DropdownMenuItem(value: Locale('pt'), child: Text('🇵🇹 PT')),
                  ],
                  onChanged: (value) {
                    if (value != null) ref.read(localeProvider.notifier).state = value;
                  },
                ),
              ),
            ),
            const ClubAdBanner(height: 60),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
