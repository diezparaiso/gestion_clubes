class ClubNotification {
  const ClubNotification({required this.id, required this.title, required this.body, required this.type, required this.target, required this.createdAt, this.isRead = false});

  final String id;
  final String title;
  final String body;
  final String type;
  final String target;
  final DateTime createdAt;
  final bool isRead;

  factory ClubNotification.fromJson(Map<String, dynamic> json) => ClubNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        target: json['target'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );
}