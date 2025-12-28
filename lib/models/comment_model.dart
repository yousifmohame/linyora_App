class CommentModel {
  final int id;
  final String content;
  final String createdAt;
  final int userId;
  final String userName;
  final String userAvatar;

  CommentModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      content: json['comment'] ?? '', // الباك اند يرسلها باسم comment
      createdAt: json['created_at'] ?? '',
      userId: json['userId'],
      userName: json['userName'] ?? 'مستخدم',
      userAvatar: json['userAvatar'] ?? '',
    );
  }
}