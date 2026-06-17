import 'city.dart';

class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String phoneNumber;
  final DateTime? birthDate;
  final String? gender;
  final String? profileImage;
  final City? city;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.phoneNumber,
    this.birthDate,
    this.gender,
    this.profileImage,
    this.city,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      birthDate:
          json['birthDate'] != null
              ? DateTime.tryParse(json['birthDate'].toString())
              : null,
      gender: json['gender'] as String?,
      profileImage: json['profileImage'] as String?,
      city:
          json['city'] != null
              ? City.fromJson(json['city'] as Map<String, dynamic>)
              : null,
    );
  }
}
