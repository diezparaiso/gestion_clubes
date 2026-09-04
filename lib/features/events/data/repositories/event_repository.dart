import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/event.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) => EventRepository());

class EventRepository {
  Future<List<ClubEvent>> listEvents(String clubId) async {
    if (!SupabaseService.isConfigured) return List.unmodifiable(_demoEvents);
    final rows = await Supabase.instance.client.from('events').select('id, title, description, location, start_at, end_at, type, visibility').eq('club_id', clubId).order('start_at');
    return rows.map(ClubEvent.fromJson).toList();
  }

  Future<List<ClubEvent>> listPublicEvents(String clubSlug) async {
    if (!SupabaseService.isConfigured) return List.unmodifiable(_demoEvents.where((event) => event.visibility == EventVisibility.public));
    final rows = await Supabase.instance.client.rpc<List<dynamic>>('get_public_events', params: {'target_club_slug': clubSlug});
    return rows.map((row) => ClubEvent.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<ClubEvent> createEvent({required String clubId, required String title, required String description, required String? location, required DateTime startAt, required DateTime endAt, required EventType type, required EventVisibility visibility}) async {
    if (!SupabaseService.isConfigured) {
      final event = ClubEvent(id: 'event-${_demoEvents.length + 1}', title: title.trim(), description: description.trim(), location: location?.trim(), startAt: startAt, endAt: endAt, type: type, visibility: visibility);
      _demoEvents.add(event);
      return event;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('La sesión ha expirado.');
    final row = await Supabase.instance.client.from('events').insert({'club_id': clubId, 'title': title.trim(), 'description': description.trim(), 'location': location?.trim(), 'start_at': startAt.toIso8601String(), 'end_at': endAt.toIso8601String(), 'type': type.name, 'visibility': visibility == EventVisibility.clubOnly ? 'club_only' : visibility.name, 'created_by': userId}).select('id, title, description, location, start_at, end_at, type, visibility').single();
    return ClubEvent.fromJson(row);
  }

  static final _demoEvents = <ClubEvent>[
    ClubEvent(id: 'event-1', title: 'Partido de liga', description: 'Jornada de liga en casa.', location: 'Campo municipal', startAt: DateTime(2026, 9, 12, 18), endAt: DateTime(2026, 9, 12, 20), type: EventType.match, visibility: EventVisibility.public),
    ClubEvent(id: 'event-2', title: 'Reunión de entrenadores', description: 'Reunión interna de planificación.', location: 'Sala del club', startAt: DateTime(2026, 9, 10, 19), endAt: DateTime(2026, 9, 10, 20), type: EventType.meeting, visibility: EventVisibility.clubOnly),
  ];
}