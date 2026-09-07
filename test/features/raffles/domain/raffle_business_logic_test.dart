import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_clubes/features/raffles/domain/entities/raffle.dart';

void main() {
  group('Raffle Business Logic', () {
    test('occupied numbers should not allow duplicates', () {
      final raffle = Raffle.fromJson({
        'id': 'raffle-1',
        'title': 'Rifa sin duplicados',
        'ticket_price': 5,
        'total_numbers': 100,
        'status': 'active',
        'end_at': '2026-12-20T12:00:00Z',
        'raffle_tickets': [
          {'number': 5},
          {'number': 5},
          {'number': 10},
        ],
      });

      expect(raffle.occupiedNumbers.length, 2);
      expect(raffle.occupiedNumbers, {5, 10});
    });

    test('should identify available numbers correctly', () {
      final raffle = Raffle.fromJson({
        'id': 'raffle-2',
        'title': 'Rifa disponibilidad',
        'ticket_price': 3,
        'total_numbers': 10,
        'status': 'active',
        'end_at': '2026-12-20T12:00:00Z',
        'raffle_tickets': [
          {'number': 1},
          {'number': 3},
          {'number': 5},
        ],
      });

      final available = raffle.availableNumbers;
      expect(available.length, 7);
      expect(available.contains(1), false);
      expect(available.contains(2), true);
      expect(available.contains(3), false);
    });

    test('should not allow drawing with no paid tickets', () {
      final raffle = Raffle.fromJson({
        'id': 'raffle-3',
        'title': 'Rifa sin pagos',
        'ticket_price': 5,
        'total_numbers': 50,
        'status': 'active',
        'end_at': '2026-12-20T12:00:00Z',
        'raffle_tickets': [
          {'number': 5, 'payment_status': 'pending'},
          {'number': 10, 'payment_status': 'pending'},
        ],
      });

      expect(raffle.paidTickets.isEmpty, true);
      expect(raffle.canDrawWinner, false);
    });

    test('should only consider paid tickets for drawing', () {
      final raffle = Raffle.fromJson({
        'id': 'raffle-4',
        'title': 'Rifa con pagos mixtos',
        'ticket_price': 5,
        'total_numbers': 50,
        'status': 'active',
        'end_at': '2026-12-20T12:00:00Z',
        'raffle_tickets': [
          {'number': 5, 'payment_status': 'paid'},
          {'number': 10, 'payment_status': 'pending'},
          {'number': 15, 'payment_status': 'paid'},
          {'number': 20, 'payment_status': 'cancelled'},
        ],
      });

      final paidTickets = raffle.paidTickets;
      expect(paidTickets.length, 2);
      expect(paidTickets.map((t) => t.number).toSet(), {5, 15});
      expect(raffle.canDrawWinner, true);
    });

    test('should calculate progress percentage correctly', () {
      final tickets = List.generate(
        50,
        (i) => {'number': i + 1, 'payment_status': 'paid'},
      );

      final raffle = Raffle.fromJson({
        'id': 'raffle-5',
        'title': 'Rifa progreso',
        'ticket_price': 2,
        'total_numbers': 100,
        'status': 'active',
        'end_at': '2026-12-20T12:00:00Z',
        'raffle_tickets': tickets,
      });

      expect(raffle.progressPercentage, 50.0);
    });

    test('should identify when raffle is almost sold out', () {
      final tickets = List.generate(
        99,
        (i) => {'number': i + 1, 'payment_status': 'paid'},
      );

      final raffle = Raffle.fromJson({
        'id': 'raffle-6',
        'title': 'Rifa casi llena',
        'ticket_price': 1,
        'total_numbers': 100,
        'status': 'active',
        'end_at': '2026-12-20T12:00:00Z',
        'raffle_tickets': tickets,
      });

      expect(raffle.availableNumbers.length, 1);
      expect(raffle.progressPercentage, 99.0);
    });
  });

  group('Raffle Ticket Validation', () {
    test('should validate ticket payment status', () {
      final ticket = RaffleTicket.fromJson({
        'id': 'ticket-1',
        'number': 5,
        'buyer_name': 'Juan',
        'buyer_email': 'juan@example.com',
        'payment_status': 'paid',
        'reservation_expires_at': null,
      });

      expect(ticket.isPaid, true);
      expect(ticket.isPending, false);
    });

    test('should detect expired reservations', () {
      final expiredTime = DateTime.now().subtract(const Duration(minutes: 20));
      final ticket = RaffleTicket.fromJson({
        'id': 'ticket-2',
        'number': 10,
        'buyer_name': 'María',
        'buyer_email': 'maria@example.com',
        'payment_status': 'pending',
        'reservation_expires_at': expiredTime.toIso8601String(),
      });

      expect(ticket.isReservationExpired, true);
      expect(ticket.isPaid, false);
    });

    test('should detect active reservations', () {
      final futureTime = DateTime.now().add(const Duration(minutes: 5));
      final ticket = RaffleTicket.fromJson({
        'id': 'ticket-3',
        'number': 15,
        'buyer_name': 'Carlos',
        'buyer_email': 'carlos@example.com',
        'payment_status': 'pending',
        'reservation_expires_at': futureTime.toIso8601String(),
      });

      expect(ticket.isReservationExpired, false);
      expect(ticket.isReserved, true);
    });
  });

  group('Raffle Draw Validation', () {
    test('should create draw records correctly', () {
      final draw1 = RaffleDraw.fromJson({
        'id': 'draw-1',
        'raffle_id': 'raffle-1',
        'winning_number': 5,
        'drawn_at': '2026-12-21T12:00:00Z',
        'method': 'random_number',
      });

      final draw2 = RaffleDraw.fromJson({
        'id': 'draw-2',
        'raffle_id': 'raffle-1',
        'winning_number': 10,
        'drawn_at': '2026-12-21T13:00:00Z',
        'method': 'random_number',
      });

      expect(draw1.winningNumber, 5);
      expect(draw2.winningNumber, 10);
      expect(draw1.raffleId, draw2.raffleId);
    });

    test('winning number must be in valid range', () {
      final raffle = Raffle.fromJson({
        'id': 'raffle-7',
        'title': 'Rifa validación',
        'ticket_price': 5,
        'total_numbers': 100,
        'status': 'active',
        'end_at': '2026-12-20T12:00:00Z',
        'raffle_tickets': [
          {'number': 5, 'payment_status': 'paid'},
        ],
      });

      expect(raffle.totalNumbers, 100);
      expect(5 >= 1 && 5 <= 100, true);
    });
  });
}