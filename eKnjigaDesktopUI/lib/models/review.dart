class Review {
  final int id;
  final double rating;
  final DateTime createdAt;
  final String? bookTitle;
  final String? userFullName;

  Review({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.bookTitle,
    this.userFullName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'],
      createdAt: DateTime.parse(json['createdAt']),
      bookTitle: json['book']?['title'],
      userFullName: json['user'] != null
          ? "${json['user']['firstName']} ${json['user']['lastName']}"
          : null,
    );
  }
}
