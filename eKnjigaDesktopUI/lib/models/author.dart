class Author {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? description;
  final List<dynamic> books;

  Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.deathDate,
    this.description,
    this.books = const [],
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      birthDate:
          json['birthDate'] != null
              ? DateTime.tryParse(json['birthDate'].toString())
              : null,
      deathDate:
          json['deathDate'] != null
              ? DateTime.tryParse(json['deathDate'].toString())
              : null,
      description: json['description'] as String?,
      books: (json['books'] as List?) ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'birthDate': birthDate?.toIso8601String(),
    'deathDate': deathDate?.toIso8601String(),
    'description': description,
    'books': books,
  };

  String get fullName => '$firstName $lastName'.trim();
}
