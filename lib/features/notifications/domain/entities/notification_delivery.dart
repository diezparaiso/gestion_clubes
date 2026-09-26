class NotificationDelivery {
  final String id;
  final String notificationId;
  final String profileId;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? title;
  final String? body;

  const NotificationDelivery({
    required this.id,
    required this.notificationId,
    required this.profileId,
    required this.readAt,
    required this.createdAt,
    this.title,
    this.body,
  });

  factory NotificationDelivery.fromJson(Map<String, dynamic> json) {
    return NotificationDelivery(
      id: json['id'] as String,
      notificationId: json['notification_id'] as String,
      profileId: json['profile_id'] as String,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      title: (json['notifications'] as Map<String, dynamic>?)?['title'] as String?,
      body: (json['notifications'] as Map<String, dynamic>?)?['body'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'notification_id': notificationId,
    'profile_id': profileId,
    'read_at': readAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'title': title,
    'body': body,
  };

  NotificationDelivery copyWith({
    String? id,
    String? notificationId,
    String? profileId,
    DateTime? readAt,
    DateTime? createdAt,
    String? title,
    String? body,
  }) {
    return NotificationDelivery(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      profileId: profileId ?? this.profileId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  bool get isRead => readAt != null;
}