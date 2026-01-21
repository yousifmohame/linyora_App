class StoryModel {
  final int id;
  final String type; // 'image', 'video', 'text', 'product'
  final String? mediaUrl;
  final String? textContent;
  final String? backgroundColor;
  final int views;
  final String createdAt;
  final String expiresAt;
  
  // ✅ الحقول الجديدة لدعم المنتجات
  final int? productId;
  final String? productName;
  final String? productImage;
  final double? productPrice;

  StoryModel({
    required this.id,
    required this.type,
    this.mediaUrl,
    this.textContent,
    this.backgroundColor,
    required this.views,
    required this.createdAt,
    required this.expiresAt,
    this.productId,
    this.productName,
    this.productImage,
    this.productPrice,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      type: json['type'] ?? 'image',
      mediaUrl: json['media_url'],
      textContent: json['text_content'],
      backgroundColor: json['background_color'],
      views: int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] ?? '',
      expiresAt: json['expires_at'] ?? '',
      
      // ✅ قراءة بيانات المنتج المرتبط (إن وجد)
      productId: int.tryParse(json['product_id']?.toString() ?? ''),
      productName: json['product_name'], // تأكد من اسم الحقل في الباك إند
      productImage: json['product_image'],
      productPrice: double.tryParse(json['product_price']?.toString() ?? ''),
    );
  }
}