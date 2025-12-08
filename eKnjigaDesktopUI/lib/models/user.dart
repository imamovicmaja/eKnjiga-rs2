class User {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;

  final DateTime? birthDate;
  final String? phone;
  final String? address;

  final bool isActive;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.birthDate,
    this.phone,
    this.address,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : null,
      phone: json['phone'],
      address: json['address'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'birthDate': birthDate?.toIso8601String(),
      'phone': phone,
      'address': address,
      'isActive': isActive,
    };
  }

  String get fullName => "$firstName $lastName";
}
