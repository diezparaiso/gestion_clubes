// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Hace seguro el repositorio de notificaciones en modo demo y restringe lecturas al usuario actual.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/notification_delivery.dart';

class NotificationDeliveryRepository {
  final SupabaseClient? _supabase;
  NotificationDeliveryRepository(this._supabase);

  Future<List<NotificationDelivery>> getUnreadDeliveries() async {
    if (!SupabaseService.isConfigured || _supabase == null) return _demoDeliveries();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');
      final response = await _supabase.from('notification_deliveries')
          .select('id, notification_id, profile_id, read_at, created_at, notifications!inner(title, body)')
          .eq('profile_id', userId).isFilter('read_at', null).order('created_at', ascending: false);
      return (response as List).map((e) => NotificationDelivery.fromJson(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) { throw Exception('Error al obtener notificaciones: ${e.message}'); }
  }

  Future<List<NotificationDelivery>> getAllDeliveries({int limit = 50}) async {
    if (!SupabaseService.isConfigured || _supabase == null) return _demoDeliveries();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');
      final response = await _supabase.from('notification_deliveries')
          .select('id, notification_id, profile_id, read_at, created_at, notifications!inner(title, body)')
          .eq('profile_id', userId).order('created_at', ascending: false).limit(limit);
      return (response as List).map((e) => NotificationDelivery.fromJson(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) { throw Exception('Error al obtener notificaciones: ${e.message}'); }
  }

  Future<void> markAsRead(String deliveryId) async {
    if (!SupabaseService.isConfigured || _supabase == null) return;
    try {
      await _supabase.rpc('mark_notification_delivery_read', params: {'p_delivery_id': deliveryId});
    } on PostgrestException catch (e) { throw Exception('Error al marcar como leído: ${e.message}'); }
  }

  Future<void> markAllAsRead() async {
    if (!SupabaseService.isConfigured || _supabase == null) return;
    try {
      await _supabase.rpc('mark_all_notification_deliveries_read');
    } on PostgrestException catch (e) { throw Exception('Error al marcar todas como leídas: ${e.message}'); }
  }

  List<NotificationDelivery> _demoDeliveries() => [
    NotificationDelivery(id: '1', notificationId: 'notif-1', profileId: 'demo-user', readAt: null, createdAt: DateTime.now().subtract(const Duration(hours: 2))),
    NotificationDelivery(id: '2', notificationId: 'notif-2', profileId: 'demo-user', readAt: DateTime.now().subtract(const Duration(hours: 1)), createdAt: DateTime.now().subtract(const Duration(hours: 3))),
    NotificationDelivery(id: '3', notificationId: 'notif-3', profileId: 'demo-user', readAt: null, createdAt: DateTime.now().subtract(const Duration(days: 1))),
  ];
}

final notificationDeliveryRepositoryProvider = Provider<NotificationDeliveryRepository>((ref) {
  final supabase = SupabaseService.isConfigured ? Supabase.instance.client : null;
  return NotificationDeliveryRepository(supabase);
});
