class NotificationDelivery {
  final String id;
  final String notificationId;
  final String profileId;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationDelivery({
    required this.id,
    required this.notificationId,
    required this.profileId,
    required this.readAt,
    required this.createdAt,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'notification_id': notificationId,
    'profile_id': profileId,
    'read_at': readAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  NotificationDelivery copyWith({
    String? id,
    String? notificationId,
    String? profileId,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationDelivery(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      profileId: profileId ?? this.profileId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isRead => readAt != null;
}