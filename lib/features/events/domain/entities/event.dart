enum EventType { match, tournament, meeting, event, fundraiser, other }
enum EventVisibility { public, clubOnly, private }

class ClubEvent {
  const ClubEvent({required this.id, required this.title, required this.description, required this.location, required this.startAt, required this.endAt, required this.type, required this.visibility});

  final String id;
  final String title;
  final String description;
  final String? location;
  final DateTime startAt;
  final DateTime endAt;
  final EventType type;
  final EventVisibility visibility;

  factory ClubEvent.fromJson(Map<String, dynamic> json) => ClubEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        location: json['location'] as String?,
        startAt: DateTime.parse(json['start_at'] as String),
        endAt: DateTime.parse(json['end_at'] as String),
        type: EventType.values.firstWhere((value) => value.name == json['type'], orElse: () => EventType.other),
        visibility: EventVisibility.values.firstWhere((value) => value.name == json['visibility'] || (value == EventVisibility.clubOnly && json['visibility'] == 'club_only'), orElse: () => EventVisibility.private),
      );
}