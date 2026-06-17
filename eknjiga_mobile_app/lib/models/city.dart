class City {
  final int id;
  final String name;
  final int zipCode;

  City({required this.id, required this.name, required this.zipCode});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      zipCode: json['zipCode'] as int? ?? 0,
    );
  }
}
