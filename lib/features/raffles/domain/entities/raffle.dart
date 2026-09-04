enum RaffleStatus { draft, scheduled, active, soldOut, closed, drawn, cancelled }

class Raffle {
  const Raffle({required this.id, required this.title, required this.ticketPrice, required this.totalNumbers, required this.status, required this.endAt, this.clubName, this.clubSlug, this.slug, this.description, this.imageUrl, this.occupiedNumbers = const {}});

  final String id;
  final String title;
  final double ticketPrice;
  final int totalNumbers;
  final RaffleStatus status;
  final DateTime endAt;
  final String? clubName;
  final String? clubSlug;
  final String? slug;
  final String? description;
  final String? imageUrl;
  final Set<int> occupiedNumbers;

  factory Raffle.fromJson(Map<String, dynamic> json) => Raffle(
    id: json['id'] as String,
    title: json['title'] as String,
    ticketPrice: (json['ticket_price'] as num).toDouble(),
    totalNumbers: json['total_numbers'] as int,
    status: RaffleStatus.values.firstWhere((value) => value.name == json['status'], orElse: () => RaffleStatus.draft),
    endAt: DateTime.parse(json['end_at'] as String),
    clubName: (json['clubs'] as Map<String, dynamic>?)?['public_name'] as String? ?? json['club_name'] as String?,
    clubSlug: (json['clubs'] as Map<String, dynamic>?)?['slug'] as String? ?? json['club_slug'] as String?,
    slug: json['slug'] as String?,
    description: json['description'] as String?,
    imageUrl: json['image_url'] as String?,
    occupiedNumbers: ((json['raffle_tickets'] as List<dynamic>?) ?? const []).map((ticket) => (ticket as Map<String, dynamic>)['number'] as int).toSet(),
  );
}

class RaffleTicket {
  const RaffleTicket({required this.id, required this.number, required this.buyerName, required this.buyerEmail, required this.paymentStatus, this.buyerPhone, this.reservationExpiresAt});

  final String id;
  final int number;
  final String buyerName;
  final String buyerEmail;
  final String paymentStatus;
  final String? buyerPhone;
  final DateTime? reservationExpiresAt;

  factory RaffleTicket.fromJson(Map<String, dynamic> json) => RaffleTicket(
        id: json['id'] as String,
        number: json['number'] as int,
        buyerName: json['buyer_name'] as String,
        buyerEmail: json['buyer_email'] as String,
        paymentStatus: json['payment_status'] as String,
        buyerPhone: json['buyer_phone'] as String?,
        reservationExpiresAt: json['reservation_expires_at'] == null ? null : DateTime.parse(json['reservation_expires_at'] as String),
      );
}

class RaffleDraw {
  const RaffleDraw({required this.id, required this.winningNumber, required this.drawnAt, required this.method});

  final String id;
  final int winningNumber;
  final DateTime drawnAt;
  final String method;

  factory RaffleDraw.fromJson(Map<String, dynamic> json) => RaffleDraw(
        id: json['id'] as String,
        winningNumber: json['winning_number'] as int,
        drawnAt: DateTime.parse(json['drawn_at'] as String),
        method: json['method'] as String,
      );
}
