class StoryModel {
  final int id;
  final String type; // 'image', 'video', 'text'
  final String? mediaUrl;
  final String? textContent;
  final String? backgroundColor;
  final int views;
  final String createdAt;
  final String expiresAt;

  StoryModel({
    required this.id,
    required this.type,
    this.mediaUrl,
    this.textContent,
    this.backgroundColor,
    required this.views,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      type: json['type'] ?? 'image',
      mediaUrl: json['media_url'],
      textContent: json['text_content'],
      backgroundColor: json['background_color'], // تأكد أن الباك إند يرسله
      views: json['views'] ?? 0,
      createdAt: json['created_at'] ?? '',
      expiresAt: json['expires_at'] ?? '',
    );
  }
}