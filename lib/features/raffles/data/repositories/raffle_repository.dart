// MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Incluye el slug público para permitir compartir la rifa desde la gestión.\n\nimport 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/raffle.dart';

final raffleRepositoryProvider = Provider<RaffleRepository>((ref) => RaffleRepository());

class RaffleRepository {
  Future<List<Raffle>> listRaffles(String clubId) async {
    if (!SupabaseService.isConfigured) return List.unmodifiable(_demoRaffles);
    final rows = await Supabase.instance.client.from('raffles').select('id, title, ticket_price, total_numbers, status, end_at, slug, clubs!inner(slug)').eq('club_id', clubId).order('created_at', ascending: false);
    return rows.map(Raffle.fromJson).toList();
  }

  Future<Raffle> getRaffle({required String clubId, required String raffleId}) async {
    if (!SupabaseService.isConfigured) return _demoRaffles.firstWhere((raffle) => raffle.id == raffleId, orElse: () => _demoRaffles.first);
    final row = await Supabase.instance.client.from('raffles').select('id, title, ticket_price, total_numbers, status, end_at, slug, clubs!inner(slug)').eq('club_id', clubId).eq('id', raffleId).single();
    return Raffle.fromJson(row);
  }

  Future<Raffle> getPublicRaffle({required String clubSlug, required String raffleSlug}) async {
    if (!SupabaseService.isConfigured) {
      final raffle = _demoRaffles.firstWhere((item) => item.slug == raffleSlug, orElse: () => _demoRaffles.first);
      return Raffle(id: raffle.id, title: raffle.title, ticketPrice: raffle.ticketPrice, totalNumbers: raffle.totalNumbers, status: raffle.status, endAt: raffle.endAt, clubName: 'Club Deportivo Paraíso', clubSlug: clubSlug, slug: raffleSlug, description: 'Participa en la rifa del club.', occupiedNumbers: {3, 7, 12, 25, 42, 68});
    }
    final row = await Supabase.instance.client.from('raffles').select('id, title, description, image_url, ticket_price, total_numbers, status, end_at, slug, clubs!inner(public_name, slug)').eq('clubs.slug', clubSlug).eq('slug', raffleSlug).eq('status', 'active').single();
    final tickets = await Supabase.instance.client.rpc<List<dynamic>>('get_public_raffle_numbers', params: {'target_club_slug': clubSlug, 'target_raffle_slug': raffleSlug});
    return Raffle.fromJson({...row, 'raffle_tickets': tickets});
  }

  Future<List<int>> reservePublicNumbers({required String clubSlug, required String raffleSlug, required List<int> numbers, required String buyerName, required String buyerEmail, String? buyerPhone}) async {
    if (!SupabaseService.isConfigured) return numbers;
    final result = await Supabase.instance.client.rpc<List<dynamic>>('reserve_public_raffle_numbers', params: {
      'target_club_slug': clubSlug,
      'target_raffle_slug': raffleSlug,
      'selected_numbers': numbers,
      'target_buyer_name': buyerName.trim(),
      'target_buyer_email': buyerEmail.trim(),
      'target_buyer_phone': buyerPhone?.trim(),
    });
    return result.cast<int>();
  }

  Future<List<RaffleTicket>> listTickets(String raffleId) async {
    if (!SupabaseService.isConfigured) return List.unmodifiable(_demoTickets.where((ticket) => ticket.id.startsWith(raffleId)));
    final rows = await Supabase.instance.client.from('raffle_tickets').select('id, number, buyer_name, buyer_email, buyer_phone, payment_status, reservation_expires_at').eq('raffle_id', raffleId).order('number');
    return rows.map(RaffleTicket.fromJson).toList();
  }

  Future<RaffleDraw> drawRaffle({required String raffleId}) async {
    if (!SupabaseService.isConfigured) {
      final ticket = _demoTickets.firstWhere((item) => item.id.startsWith(raffleId) && item.paymentStatus == 'paid', orElse: () => _demoTickets.first);
      return RaffleDraw(id: 'draw-$raffleId', winningNumber: ticket.number, drawnAt: DateTime.now(), method: 'random_number');
    }
    final row = await Supabase.instance.client.rpc<Map<String, dynamic>>('draw_raffle_random', params: {'target_raffle_id': raffleId});
    return RaffleDraw.fromJson(row);
  }

  // MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Valida invariantes de negocio antes del alta y activa las rifas nuevas.
  Future<Raffle> createRaffle({required String clubId, required String title, required double ticketPrice, required int totalNumbers, required DateTime endAt}) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) throw const FormatException('El título de la rifa es obligatorio.');
    if (!ticketPrice.isFinite || ticketPrice <= 0) throw const FormatException('El precio debe ser mayor que 0.');
    if (totalNumbers < 1 || totalNumbers > 100000) throw const FormatException('El total de números debe estar entre 1 y 100000.');
    if (!endAt.isAfter(DateTime.now())) throw const FormatException('La fecha de finalización debe ser futura.');

    if (!SupabaseService.isConfigured) {
      final raffle = Raffle(id: 'raffle-${_demoRaffles.length + 1}', title: normalizedTitle, ticketPrice: ticketPrice, totalNumbers: totalNumbers, status: RaffleStatus.active, endAt: endAt);
      _demoRaffles.insert(0, raffle);
      return raffle;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('La sesión ha expirado.');
    final slug = normalizedTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final row = await Supabase.instance.client.from('raffles').insert({'club_id': clubId, 'title': normalizedTitle, 'slug': slug.isEmpty ? 'rifa' : slug, 'ticket_price': ticketPrice, 'total_numbers': totalNumbers, 'start_at': DateTime.now().toIso8601String(), 'end_at': endAt.toIso8601String(), 'draw_at': endAt.toIso8601String(), 'status': 'active', 'created_by': userId}).select('id, title, ticket_price, total_numbers, status, end_at, slug, clubs!inner(slug)').single();
    return Raffle.fromJson(row);
  }

  static final _demoRaffles = <Raffle>[
    Raffle(id: 'raffle-1', title: 'Rifa Navidad', ticketPrice: 5, totalNumbers: 100, status: RaffleStatus.active, endAt: DateTime(2026, 12, 20), clubSlug: 'club-paraiso', slug: 'rifa-navidad'),
    Raffle(id: 'raffle-2', title: 'Cesta del club', ticketPrice: 3, totalNumbers: 200, status: RaffleStatus.scheduled, endAt: DateTime(2026, 11, 30), slug: 'cesta-del-club'),
  ];

  static final _demoTickets = <RaffleTicket>[
    const RaffleTicket(id: 'raffle-1-ticket-03', number: 3, buyerName: 'Ana García', buyerEmail: 'ana@example.com', paymentStatus: 'paid'),
    const RaffleTicket(id: 'raffle-1-ticket-12', number: 12, buyerName: 'Luis Martín', buyerEmail: 'luis@example.com', paymentStatus: 'pending'),
    const RaffleTicket(id: 'raffle-1-ticket-42', number: 42, buyerName: 'Marta López', buyerEmail: 'marta@example.com', paymentStatus: 'paid'),
  ];
}
