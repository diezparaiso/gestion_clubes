enum RaffleType { cesta, sorteoPuro }

enum RaffleStatus { draft, scheduled, active, soldOut, closed, drawn, cancelled }

class Raffle {
  const Raffle({
    required this.id,
    required this.title,
    required this.ticketPrice,
    required this.totalNumbers,
    required this.status,
    required this.endAt,
    this.type = RaffleType.sorteoPuro,
    this.winningNumber,
    this.clubName,
    this.clubSlug,
    this.slug,
    this.description,
    this.imageUrl,
    this.occupiedNumbers = const {},
    this.tickets = const [],
  });

  final String id;
  final String title;
  final double ticketPrice;
  final int totalNumbers;
  final RaffleStatus status;
  final DateTime endAt;
  final RaffleType type;
  final int? winningNumber;
  final String? clubName;
  final String? clubSlug;
  final String? slug;
  final String? description;
  final String? imageUrl;
  final Set<int> occupiedNumbers;
  final List<RaffleTicket> tickets;

  // Getters de negocio
  Set<int> get availableNumbers {
    final all = <int>{};
    for (int i = 1; i <= totalNumbers; i++) {
      all.add(i);
    }
    return all.difference(occupiedNumbers);
  }

  List<RaffleTicket> get paidTickets =>
      tickets.where((t) => t.paymentStatus == 'paid').toList();

  bool get canDrawWinner => paidTickets.isNotEmpty;

  double get progressPercentage =>
      totalNumbers > 0 ? (occupiedNumbers.length / totalNumbers) * 100 : 0;

  factory Raffle.fromJson(Map<String, dynamic> json) => Raffle(
        id: json['id'] as String,
        title: json['title'] as String,
        ticketPrice: (json['ticket_price'] as num).toDouble(),
        totalNumbers: json['total_numbers'] as int,
        type: RaffleType.values.firstWhere((value) => value.name == (json['raffle_type'] as String? ?? 'sorteoPuro'), orElse: () => RaffleType.sorteoPuro),
        winningNumber: json['winning_number'] as int?,
        status: RaffleStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => RaffleStatus.draft,
        ),
        endAt: DateTime.parse(json['end_at'] as String),
        clubName: (json['clubs'] as Map<String, dynamic>?)
                ?['public_name'] as String? ??
            json['club_name'] as String?,
        clubSlug:
            (json['clubs'] as Map<String, dynamic>?)?['slug'] as String? ??
                json['club_slug'] as String?,
        slug: json['slug'] as String?,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        occupiedNumbers: ((json['raffle_tickets'] as List<dynamic>?) ?? const [])
            .map((ticket) => (ticket as Map<String, dynamic>)['number'] as int)
            .toSet(),
        tickets: ((json['raffle_tickets'] as List<dynamic>?) ?? const [])
            .map((ticket) =>
                RaffleTicket.fromJson(ticket as Map<String, dynamic>))
            .toList(),
      );
}

class RaffleTicket {
  const RaffleTicket({
    required this.id,
    required this.number,
    required this.buyerName,
    required this.buyerEmail,
    required this.paymentStatus,
    this.buyerPhone,
    this.reservationExpiresAt,
    this.raffleId,
  });

  final String id;
  final int number;
  final String buyerName;
  final String buyerEmail;
  final String paymentStatus;
  final String? buyerPhone;
  final DateTime? reservationExpiresAt;
  final String? raffleId;

  // Getters de negocio
  bool get isPaid => paymentStatus == 'paid';

  bool get isPending => paymentStatus == 'pending';

  bool get isReservationExpired {
    if (reservationExpiresAt == null) return false;
    return reservationExpiresAt!.isBefore(DateTime.now());
  }

  bool get isReserved =>
      isPending && reservationExpiresAt != null && !isReservationExpired;

  factory RaffleTicket.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final numberRaw = json['number'];
    final buyerNameRaw = json['buyer_name'];
    final buyerEmailRaw = json['buyer_email'];
    final paymentStatusRaw = json['payment_status'];
    final buyerPhoneRaw = json['buyer_phone'];
    final raffleIdRaw = json['raffle_id'];
    final reservationRaw = json['reservation_expires_at'];

    return RaffleTicket(
      // Si no viene 'id' (como en los tests de disponibilidad de números),
      // generamos uno basado en el número de ticket para no romper el parsing.
      id: idRaw is String ? idRaw : 'ticket-${numberRaw ?? 'unknown'}',
      number: numberRaw as int,
      buyerName: buyerNameRaw is String ? buyerNameRaw : 'Unknown',
      buyerEmail:
          buyerEmailRaw is String ? buyerEmailRaw : 'unknown@example.com',
      paymentStatus: paymentStatusRaw is String ? paymentStatusRaw : 'pending',
      buyerPhone: buyerPhoneRaw is String ? buyerPhoneRaw : null,
      reservationExpiresAt:
          reservationRaw is String ? DateTime.parse(reservationRaw) : null,
      raffleId: raffleIdRaw is String ? raffleIdRaw : null,
    );
  }
}

class RaffleDraw {
  const RaffleDraw({
    required this.id,
    required this.winningNumber,
    required this.drawnAt,
    required this.method,
    this.raffleId,
  });

  final String id;
  final int winningNumber;
  final DateTime drawnAt;
  final String method;
  final String? raffleId;

  factory RaffleDraw.fromJson(Map<String, dynamic> json) => RaffleDraw(
        id: json['id'] as String,
        winningNumber: json['winning_number'] as int,
        drawnAt: DateTime.parse(json['drawn_at'] as String),
        method: json['method'] as String,
        raffleId: json['raffle_id'] as String?,
      );
}