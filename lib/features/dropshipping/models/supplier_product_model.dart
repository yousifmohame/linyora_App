class SupplierVariant {
  final int id;
  final String color;
  final double costPrice;
  final int stockQuantity;
  final List<String> images;

  SupplierVariant({
    required this.id,
    required this.color,
    required this.costPrice,
    required this.stockQuantity,
    required this.images,
  });

  factory SupplierVariant.fromJson(Map<String, dynamic> json) {
    return SupplierVariant(
      id: json['id'],
      color: json['color'] ?? '',
      costPrice: double.tryParse(json['cost_price'].toString()) ?? 0.0,
      stockQuantity: int.tryParse(json['stock_quantity'].toString()) ?? 0,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
    );
  }
}

class SupplierProduct {
  final int id;
  final String name;
  final String brand;
  final String description;
  final String? supplierName;
  final bool isFeatured;
  final String categories; // Comma separated string
  final List<SupplierVariant> variants;

  SupplierProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    this.supplierName,
    required this.isFeatured,
    required this.categories,
    required this.variants,
  });

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    return SupplierProduct(
      id: json['id'],
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      description: json['description'] ?? '',
      supplierName: json['supplier_name'],
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      categories: json['categories'] ?? '',
      variants: json['variants'] != null
          ? (json['variants'] as List).map((v) => SupplierVariant.fromJson(v)).toList()
          : [],
    );
  }
}