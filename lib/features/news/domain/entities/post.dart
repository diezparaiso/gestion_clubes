enum PostStatus { draft, published, archived }

class Post {
  const Post({required this.id, required this.title, required this.body, required this.status, this.imageUrl, this.publishedAt, this.createdAt});

  final String id;
  final String title;
  final String body;
  final PostStatus status;
  final String? imageUrl;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        status: PostStatus.values.firstWhere((value) => value.name == json['status'], orElse: () => PostStatus.draft),
        imageUrl: json['image_url'] as String?,
        publishedAt: json['published_at'] == null ? null : DateTime.parse(json['published_at'] as String),
        createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
      );
}