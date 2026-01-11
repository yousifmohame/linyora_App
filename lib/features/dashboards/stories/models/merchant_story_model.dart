class MerchantStory {
  final int id;
  final String? mediaUrl; // يمكن أن يكون null للنص
  final String mediaType; // 'image', 'video', 'text'
  final String? textContent; // محتوى النص
  final String? backgroundColor; // لون الخلفية للنص
  final int views;
  final DateTime createdAt;
  final DateTime? expiresAt;

  MerchantStory({
    required this.id,
    this.mediaUrl,
    required this.mediaType,
    this.textContent,
    this.backgroundColor,
    required this.views,
    required this.createdAt,
    this.expiresAt,
  });

  factory MerchantStory.fromJson(Map<String, dynamic> json) {
    // معالجة الرابط: إذا كان نص فارغ أو "null" نحوله لـ null حقيقي
    String? url = json['media_url'] ?? json['media'] ?? json['image'];
    if (url != null && (url.isEmpty || url == 'null')) {
      url = null;
    }

    return MerchantStory(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      mediaUrl: url,
      // التأكد من قراءة النوع بدقة، والافتراضي 'image' فقط إذا لم يحدد
      mediaType: json['type'] ?? json['media_type'] ?? 'image',
      textContent: json['text_content'],
      backgroundColor: json['background_color'],
      views: int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      expiresAt:
          json['expires_at'] != null
              ? DateTime.tryParse(json['expires_at'].toString())
              : null,
    );
  }
}
