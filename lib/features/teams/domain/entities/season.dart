class Season {
  const Season({required this.id, required this.name});

  final String id;
  final String name;

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(id: json['id'] as String, name: json['name'] as String);
  }
}
