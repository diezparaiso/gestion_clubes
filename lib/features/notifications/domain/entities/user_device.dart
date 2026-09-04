enum DevicePlatform { web, android, ios }
enum PermissionStatus { unknown, granted, denied }

class UserDevice {
  const UserDevice({required this.id, required this.platform, required this.permissionStatus, required this.lastSeenAt});

  final String id;
  final DevicePlatform platform;
  final PermissionStatus permissionStatus;
  final DateTime lastSeenAt;

  factory UserDevice.fromJson(Map<String, dynamic> json) => UserDevice(
        id: json['id'] as String,
        platform: DevicePlatform.values.firstWhere((value) => value.name == json['platform'], orElse: () => DevicePlatform.web),
        permissionStatus: PermissionStatus.values.firstWhere((value) => value.name == json['permission_status'], orElse: () => PermissionStatus.unknown),
        lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      );
}