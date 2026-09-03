class Club {
  const Club({required this.id, required this.publicName, required this.slug});

  final String id;
  final String publicName;
  final String slug;

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String,
      publicName: json['public_name'] as String,
      slug: json['slug'] as String,
    );
  }
}
