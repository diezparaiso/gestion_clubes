import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository());

class NotificationRepository {
  Future<List<ClubNotification>> listNotifications(String clubId) async {
    if (!SupabaseService.isConfigured) return List.unmodifiable(_demoNotifications);
    final rows = await Supabase.instance.client.from('notifications').select('id, title, body, type, target, created_at').eq('club_id', clubId).order('created_at', ascending: false);
    return rows.map(ClubNotification.fromJson).toList();
  }

  static final _demoNotifications = <ClubNotification>[
    ClubNotification(id: 'notification-1', title: 'Nueva noticia publicada', body: 'Ya puedes consultar la información de la nueva temporada.', type: 'news', target: 'all_members', createdAt: DateTime(2026, 9, 4)),
    ClubNotification(id: 'notification-2', title: 'Próximo partido', body: 'El equipo juega este sábado a las 18:00 en casa.', type: 'event', target: 'all_members', createdAt: DateTime(2026, 9, 3)),
  ];
}