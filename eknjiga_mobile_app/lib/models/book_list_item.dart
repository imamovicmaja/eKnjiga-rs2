class BookListItem {
  final int id;
  final String name;
  final double rating;
  final int ratingCount;
  final List<String> authors;
  final List<int> authorIds;
  final String? coverImage;

  BookListItem({
    required this.id,
    required this.name,
    required this.rating,
    required this.ratingCount,
    required this.authors,
    required this.authorIds,
    required this.coverImage,
  });

  factory BookListItem.fromJson(Map<String, dynamic> json) {
    final authorsJson = (json['authors'] as List?) ?? [];

    return BookListItem(
      id: json['id'],
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] ?? 0,
      authors: authorsJson
          .map((a) => "${a['firstName'] ?? ''} ${a['lastName'] ?? ''}".trim())
          .toList()
          .cast<String>(),
      authorIds: authorsJson
          .map((a) => a['id'] as int)
          .toList()
          .cast<int>(),
      coverImage: json['coverImage'],
    );
  }
}