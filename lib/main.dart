// MODIFICADO POR GPT-5.6 LUNA (2026-09-27): la publicidad espera consentimiento antes de inicializar AdSense.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/supabase_service.dart';
import 'core/config/ads_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  AdsService.initialize();
  runApp(const ProviderScope(child: ClubPlatformApp()));
}
