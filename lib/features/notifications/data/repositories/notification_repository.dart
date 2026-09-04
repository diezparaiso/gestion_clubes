import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/user_device.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository());

class NotificationRepository {
  Future<List<ClubNotification>> listNotifications(String clubId) async {
    if (!SupabaseService.isConfigured) return List.unmodifiable(_demoNotifications);
    final rows = await Supabase.instance.client.from('notifications').select('id, title, body, type, target, created_at').eq('club_id', clubId).order('created_at', ascending: false);
    return rows.map(ClubNotification.fromJson).toList();
  }

  Future<ClubNotification> createNotification({required String clubId, required String title, required String body, required String type, required String target}) async {
    if (!SupabaseService.isConfigured) {
      final notification = ClubNotification(id: 'notification-${_demoNotifications.length + 1}', title: title.trim(), body: body.trim(), type: type, target: target, createdAt: DateTime.now());
      _demoNotifications.insert(0, notification);
      return notification;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('La sesión ha expirado.');
    final row = await Supabase.instance.client.from('notifications').insert({'club_id': clubId, 'title': title.trim(), 'body': body.trim(), 'type': type, 'target': target}).select('id, title, body, type, target, created_at').single();
    return ClubNotification.fromJson(row);
  }

  Future<UserDevice?> registerDevice({required String token, required DevicePlatform platform, required PermissionStatus permissionStatus}) async {
    if (!SupabaseService.isConfigured) return null;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('La sesión ha expirado.');
    final row = await Supabase.instance.client.from('user_devices').upsert({
      'profile_id': userId,
      'platform': platform.name,
      'token': token,
      'permission_status': permissionStatus.name,
      'last_seen_at': DateTime.now().toIso8601String(),
    }, onConflict: 'platform,token').select('id, platform, permission_status, last_seen_at').single();
    return UserDevice.fromJson(row);
  }

  Future<void> unregisterDevice(String token) async {
    if (!SupabaseService.isConfigured) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client.from('user_devices').delete().eq('profile_id', userId).eq('token', token);
  }

  static final _demoNotifications = <ClubNotification>[
    ClubNotification(id: 'notification-1', title: 'Nueva noticia publicada', body: 'Ya puedes consultar la información de la nueva temporada.', type: 'news', target: 'all_members', createdAt: DateTime(2026, 9, 4)),
    ClubNotification(id: 'notification-2', title: 'Próximo partido', body: 'El equipo juega este sábado a las 18:00 en casa.', type: 'event', target: 'all_members', createdAt: DateTime(2026, 9, 3)),
  ];
}