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
