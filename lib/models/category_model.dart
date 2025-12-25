class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String imageUrl;
  final int productCount;
  final bool isFeatured;
  final bool isTrending;
  final List<CategoryModel> children;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    this.productCount = 0,
    this.isFeatured = false,
    this.isTrending = false,
    this.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // معالجة القائمة الفرعية بشكل آمن
    var childrenList = <CategoryModel>[];
    if (json['children'] != null) {
      childrenList = (json['children'] as List)
          .map((i) => CategoryModel.fromJson(i))
          .toList();
    }

    // معالجة رابط الصورة (إصلاح المسارات في ويندوز إذا كانت محلية)
    String img = json['image_url'] ?? '';
    if (img.isNotEmpty) {
      img = img.replaceAll('\\', '/');
      // إذا كان الرابط لا يبدأ بـ http، قد تحتاج لإضافة الدومين الأساسي هنا
      // if (!img.startsWith('http')) img = 'YOUR_BASE_URL/$img';
    }

    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      imageUrl: img,
      productCount: json['product_count'] ?? 0, // مهم لعرض "15 منتج"
      
      // تحويل القيم بمرونة (سواء جاءت 1/0 أو true/false)
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      isTrending: json['is_trending'] == 1 || json['is_trending'] == true,
      
      children: childrenList,
    );
  }
}