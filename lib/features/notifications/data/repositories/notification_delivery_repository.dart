import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/notification_delivery.dart';

class NotificationDeliveryRepository {
  final SupabaseClient _supabase;

  NotificationDeliveryRepository(this._supabase);

  /// Obtiene todas las notificaciones no leídas del usuario actual
  Future<List<NotificationDelivery>> getUnreadDeliveries() async {
    if (!SupabaseService.isConfigured) {
      return _demoDeliveries();
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await _supabase
          .from('notification_deliveries')
          .select()
          .eq('profile_id', userId)
          .isFilter('read_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => NotificationDelivery.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener notificaciones: ${e.message}');
    }
  }

  /// Obtiene todas las entregas del usuario actual (leídas y no leídas)
  Future<List<NotificationDelivery>> getAllDeliveries({
    int limit = 50,
  }) async {
    if (!SupabaseService.isConfigured) {
      return _demoDeliveries();
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await _supabase
          .from('notification_deliveries')
          .select()
          .eq('profile_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => NotificationDelivery.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener notificaciones: ${e.message}');
    }
  }

  /// Marca una entrega como leída
  Future<void> markAsRead(String deliveryId) async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    try {
      await _supabase
          .from('notification_deliveries')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', deliveryId);
    } on PostgrestException catch (e) {
      throw Exception('Error al marcar como leído: ${e.message}');
    }
  }

  /// Marca todas las entregas como leídas
  Future<void> markAllAsRead() async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await _supabase
          .from('notification_deliveries')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('profile_id', userId)
          .isFilter('read_at', null);
    } on PostgrestException catch (e) {
      throw Exception('Error al marcar todas como leídas: ${e.message}');
    }
  }

  /// Datos demo para desarrollo
  List<NotificationDelivery> _demoDeliveries() {
    return [
      NotificationDelivery(
        id: '1',
        notificationId: 'notif-1',
        profileId: 'demo-user',
        readAt: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationDelivery(
        id: '2',
        notificationId: 'notif-2',
        profileId: 'demo-user',
        readAt: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      NotificationDelivery(
        id: '3',
        notificationId: 'notif-3',
        profileId: 'demo-user',
        readAt: null,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}

/// Provider de Riverpod
final notificationDeliveryRepositoryProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  return NotificationDeliveryRepository(supabase);
});