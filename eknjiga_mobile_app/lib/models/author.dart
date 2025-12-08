class Author {
  final int id;
  final String firstName;
  final String lastName;

  Author({required this.id, required this.firstName, required this.lastName});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }
}
