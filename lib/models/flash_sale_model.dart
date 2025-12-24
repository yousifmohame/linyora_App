import '../core/utils/image_helper.dart';

class FlashProduct {
  final int id;
  final String name;
  final double originalPrice;
  final double discountPrice;
  final int sold;
  final int total;
  final String image;
  final int discountPercent;

  FlashProduct({
    required this.id,
    required this.name,
    required this.originalPrice,
    required this.discountPrice,
    required this.sold,
    required this.total,
    required this.image,
    required this.discountPercent,
  });

  factory FlashProduct.fromJson(Map<String, dynamic> json) {
    double orig = double.tryParse(json['originalPrice'].toString()) ?? 0.0;
    double disc = double.tryParse(json['discountPrice'].toString()) ?? 0.0;
    
    // حساب النسبة المئوية إذا لم تأتِ من السيرفر
    int percent = 0;
    if (orig > 0) {
      percent = ((orig - disc) / orig * 100).round();
    }

    return FlashProduct(
      id: json['id'],
      name: json['name'] ?? '',
      originalPrice: orig,
      discountPrice: disc,
      sold: json['sold'] ?? 0,
      total: json['total'] ?? 100,
      image: ImageHelper.getValidUrl(json['image']),
      discountPercent: percent,
    );
  }
}

class FlashSaleCampaign {
  final int id;
  final String title;
  final DateTime endTime;
  final List<FlashProduct> products;

  FlashSaleCampaign({
    required this.id,
    required this.title,
    required this.endTime,
    required this.products,
  });

  factory FlashSaleCampaign.fromJson(Map<String, dynamic> json) {
    return FlashSaleCampaign(
      id: json['id'],
      title: json['title'] ?? 'عروض فلاش',
      endTime: DateTime.parse(json['endTime']), // تأكد أن التنسيق ISO 8601
      products: (json['products'] as List)
          .map((e) => FlashProduct.fromJson(e))
          .toList(),
    );
  }
}