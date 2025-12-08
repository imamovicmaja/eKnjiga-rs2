class CommentReaction {
  final int userId;
  final int? commentId;
  final int? commentAnswerId;
  final bool isLike;

  CommentReaction({
    required this.userId,
    this.commentId,
    this.commentAnswerId,
    required this.isLike,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'commentId': commentId,
    'commentAnswerId': commentAnswerId,
    'isLike': isLike,
  };
}
