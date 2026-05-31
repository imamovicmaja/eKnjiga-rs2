class Book {
  final int id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final List<String> authors;
  final List<int> authorIds;
  final List<int> categoryIds;
  final String? coverImage;

  Book({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.ratingCount,
    required this.createdAt,
    required this.authors,
    required this.authorIds,
    required this.categoryIds,
    required this.coverImage,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final authorsJson = (json['authors'] as List?) ?? [];
    final categoriesJson = (json['categories'] as List?) ?? [];

    return Book(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      authors: authorsJson
          .map((a) => "${a['firstName'] ?? ''} ${a['lastName'] ?? ''}".trim())
          .toList()
          .cast<String>(),
      authorIds: authorsJson
          .map((a) => a['id'] as int)
          .toList()
          .cast<int>(),
      categoryIds: categoriesJson
          .map((c) => c['id'] as int)
          .toList()
          .cast<int>(),
      coverImage: json['coverImage'],
    );
  }
}