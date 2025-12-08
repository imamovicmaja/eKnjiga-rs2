class Comment {
  final int id;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int dislikes;
  final User user;
  final List<CommentReply> replies;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
    required this.user,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      likes: json['likes'],
      dislikes: json['dislikes'],
      user: User.fromJson(json['user']),
      replies: (json['replies'] as List)
          .map((r) => CommentReply.fromJson(r))
          .toList(),
    );
  }
}

class CommentReply {
  final int id;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int dislikes;
  final User user;

  CommentReply({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
    required this.user,
  });

  factory CommentReply.fromJson(Map<String, dynamic> json) {
    return CommentReply(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      likes: json['likes'],
      dislikes: json['dislikes'],
      user: User.fromJson(json['user']),
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

