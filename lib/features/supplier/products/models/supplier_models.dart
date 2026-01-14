class SupplierVariant {
  int? id;
  String color;
  double costPrice;
  int stockQuantity;
  List<String> images;

  SupplierVariant({
    this.id,
    required this.color,
    required this.costPrice,
    required this.stockQuantity,
    required this.images,
  });

  factory SupplierVariant.fromJson(Map<String, dynamic> json) {
    return SupplierVariant(
      id: json['id'],
      color: json['color'] ?? '',
      costPrice: double.tryParse(json['cost_price']?.toString() ?? '0') ?? 0.0,
      stockQuantity:
          int.tryParse(json['stock_quantity']?.toString() ?? '0') ?? 0,
      // تأكد أن الصور تأتي كقائمة نصوص
      images: json['images'] != null ? List<String>.from(json['images']) : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'color': color,
    'cost_price': costPrice,
    'stock_quantity': stockQuantity,
    'images': images,
  };
}

class SupplierProduct {
  int? id;
  String name;
  String brand;
  String description;
  List<SupplierVariant> variants;
  List<int> categoryIds;

  SupplierProduct({
    this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.variants,
    this.categoryIds = const [],
  });

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    return SupplierProduct(
      id: json['id'],
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      description: json['description'] ?? '',
      variants:
          (json['variants'] as List?)
              ?.map((v) => SupplierVariant.fromJson(v))
              .toList() ??
          [],
      categoryIds:
          (json['categoryIds'] as List?)?.map((e) => e as int).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'brand': brand,
    'description': description,
    'variants': variants.map((v) => v.toJson()).toList(),
    'categoryIds': categoryIds,
  };
}

class Category {
  final int id;
  final String name;
  final List<Category> children;

  Category({required this.id, required this.name, this.children = const []});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      children:
          (json['children'] as List?)
              ?.map((c) => Category.fromJson(c))
              .toList() ??
          [],
    );
  }
}
