class Club {
  const Club({required this.id, required this.publicName, required this.slug, this.website, this.instagramUrl, this.facebookUrl, this.youtubeUrl});

  final String id;
  final String publicName;
  final String slug;
  final String? website;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? youtubeUrl;

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String,
      publicName: json['public_name'] as String,
      slug: json['slug'] as String,
      website: json['website'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      facebookUrl: json['facebook_url'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
    );
  }
}
