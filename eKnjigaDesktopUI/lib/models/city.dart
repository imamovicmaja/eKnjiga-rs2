import 'country.dart';

class City {
  final int id;
  final String name;
  final int zipCode;
  final Country country;

  City({required this.id, required this.name, required this.zipCode, required this.country});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      name: json['name'],
      country: Country.fromJson(json['country']),
      zipCode: json['zipCode'],
    );
  }
}
