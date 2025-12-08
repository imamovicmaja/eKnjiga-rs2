import 'book.dart';

class Author {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? description;
  final List<Book> books;

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
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      deathDate: json['deathDate'] != null
          ? DateTime.parse(json['deathDate'] as String)
          : null,
      description: json['description'] as String?,
      books: (json['books'] as List<dynamic>?)
              ?.map((b) => Book.fromJson(b as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate?.toIso8601String(),
      'deathDate': deathDate?.toIso8601String(),
      'description': description,
    };
  }
}
