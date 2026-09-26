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
