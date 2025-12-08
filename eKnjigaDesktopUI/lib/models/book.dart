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
  final String? coverImageBase64;
  final String? pdfFileBase64;

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
    required this.coverImageBase64,
    required this.pdfFileBase64,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      ratingCount: json['ratingCount'],
      createdAt: DateTime.parse(json['createdAt']),
      authors: (json['authors'] as List)
        .map((a) => "${a['firstName']} ${a['lastName']}")
        .toList(),
      authorIds: (json['authors'] as List).map((a) => a['id'] as int).toList(),
      categoryIds: (json['categories'] as List).map((c) => c['id'] as int).toList(),
      coverImageBase64: json['coverImage'],
      pdfFileBase64: json['pdfFile'],
    );
  }
}
