class CommentAnswer {
  final int id;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int dislikes;
  final User user;
  final ParentComment parentComment;

  CommentAnswer({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
    required this.user,
    required this.parentComment,
  });

  factory CommentAnswer.fromJson(Map<String, dynamic> json) {
    return CommentAnswer(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      likes: json['likes'],
      dislikes: json['dislikes'],
      user: User.fromJson(json['user']),
      parentComment: ParentComment.fromJson(json['parentComment']),
    );
  }
}

class ParentComment {
  final int id;
  final String content;

  ParentComment({
    required this.id,
    required this.content,
  });

  factory ParentComment.fromJson(Map<String, dynamic> json) {
    return ParentComment(
      id: json['id'],
      content: json['content'],
    );
  }
}

class User {
  final String firstName;
  final String lastName;

  User({
    required this.firstName,
    required this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }
}