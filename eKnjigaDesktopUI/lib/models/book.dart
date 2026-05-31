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
    return Book(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),

      authors: (json['authors'] as List?)
              ?.map((e) {
                if (e is String) return e;

                if (e is Map<String, dynamic>) {
                  final firstName = e['firstName']?.toString() ?? '';
                  final lastName = e['lastName']?.toString() ?? '';
                  final fullName = '$firstName $lastName'.trim();

                  if (fullName.isNotEmpty) return fullName;
                }

                return '';
              })
              .where((name) => name.isNotEmpty)
              .toList() ??
          [],

      authorIds: (json['authorIds'] as List?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .where((id) => id > 0)
              .toList() ??
          [],

      categoryIds: (json['categoryIds'] as List?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .where((id) => id > 0)
              .toList() ??
          [],

      coverImage: json['coverImage'] as String?,
    );
  }
}