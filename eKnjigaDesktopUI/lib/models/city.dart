import 'country.dart';

class City {
  final int id;
  final String name;
  final int zipCode;
  final Country? country;

  City({
    required this.id,
    required this.name,
    required this.zipCode,
    this.country,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      zipCode: (json['zipCode'] as num?)?.toInt() ?? 0,
      country:
          json['country'] != null
              ? Country.fromJson(json['country'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'zipCode': zipCode,
    'country': country?.toJson(),
    'countryId': country?.id,
  };
}
