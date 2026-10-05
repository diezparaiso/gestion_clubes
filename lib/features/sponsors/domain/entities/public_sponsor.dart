class PublicSponsor {
  const PublicSponsor({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.website,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? website;

  factory PublicSponsor.fromJson(Map<String, dynamic> json) => PublicSponsor(
        id: json['id'] as String,
        name: json['name'] as String,
        logoUrl: json['logo_url'] as String?,
        website: json['website'] as String?,
      );
}
