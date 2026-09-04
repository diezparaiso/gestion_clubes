import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_clubes/features/raffles/domain/entities/raffle.dart';

void main() {
  group('Raffle entities', () {
    test('parses raffle metadata and occupied numbers', () {
      final raffle = Raffle.fromJson({
        'id': 'raffle-1',
        'title': 'Rifa de prueba',
        'ticket_price': 5,
        'total_numbers': 10,
        'status': 'active',
        'end_at': '2026-12-20T12:00:00Z',
        'clubs': {'public_name': 'Club Demo', 'slug': 'club-demo'},
        'raffle_tickets': [
          {'number': 2},
          {'number': 7},
        ],
      });

      expect(raffle.status, RaffleStatus.active);
      expect(raffle.ticketPrice, 5);
      expect(raffle.occupiedNumbers, {2, 7});
      expect(raffle.clubName, 'Club Demo');
    });

    test('falls back to draft for an unknown status', () {
      final raffle = Raffle.fromJson({
        'id': 'raffle-2',
        'title': 'Rifa',
        'ticket_price': 3.5,
        'total_numbers': 20,
        'status': 'future_status',
        'end_at': '2026-12-20T12:00:00Z',
      });

      expect(raffle.status, RaffleStatus.draft);
    });

    test('parses ticket and draw records', () {
      final ticket = RaffleTicket.fromJson({
        'id': 'ticket-1',
        'number': 4,
        'buyer_name': 'Ana',
        'buyer_email': 'ana@example.com',
        'payment_status': 'paid',
        'reservation_expires_at': null,
      });
      final draw = RaffleDraw.fromJson({
        'id': 'draw-1',
        'winning_number': 4,
        'drawn_at': '2026-12-21T12:00:00Z',
        'method': 'random_number',
      });

      expect(ticket.paymentStatus, 'paid');
      expect(ticket.number, 4);
      expect(draw.winningNumber, 4);
      expect(draw.method, 'random_number');
    });
  });
}
