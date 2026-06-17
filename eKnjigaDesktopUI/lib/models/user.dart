import 'city.dart';
import 'role.dart';

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phoneNumber;
  final DateTime? birthDate;
  final String? gender;
  final DateTime? createdAt;
  final String? profileImage;
  final City? city;
  final Role? role;
  final bool isActive;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.birthDate,
    this.gender,
    this.createdAt,
    this.profileImage,
    this.city,
    this.role,
    this.isActive = true,
    String? phone,
    String? address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? json['phone'] as String?,
      birthDate:
          json['birthDate'] != null
              ? DateTime.tryParse(json['birthDate'].toString())
              : null,
      gender: json['gender'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null,
      profileImage: json['profileImage'] as String?,
      city:
          json['city'] != null
              ? City.fromJson(json['city'] as Map<String, dynamic>)
              : null,
      role:
          json['role'] != null
              ? Role.fromJson(json['role'] as Map<String, dynamic>)
              : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'createdAt': createdAt?.toIso8601String(),
      'profileImage': profileImage,
      'city': city?.toJson(),
      'cityId': city?.id,
      'role': role?.toJson(),
      'roleId': role?.id,
      'isActive': isActive,
    };
  }

  String get fullName {
    final joined = [
      firstName,
      lastName,
    ].where((x) => x.trim().isNotEmpty).join(' ');
    return joined.isNotEmpty ? joined : username;
  }

  String get roleName => role?.name ?? '';
  String get cityName => city?.name ?? '';
}
