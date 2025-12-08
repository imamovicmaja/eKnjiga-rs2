class UserReport {
  final int id;
  final String reason;
  final int status;
  final DateTime createdAt;
  final User userReported;
  final User reportedByUser;

  UserReport({
    required this.id,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.userReported,
    required this.reportedByUser,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      id: json['id'],
      reason: json['reason'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      userReported: User.fromJson(json['userReported']),
      reportedByUser: User.fromJson(json['reportedByUser']),
    );
  }
}

class User {
  final int id;
  final String firstName;
  final String lastName;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }
}
