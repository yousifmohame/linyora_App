class CartItemModel {
  final int id;
  final int productId;
  final String name;
  final String image;
  final double price;
  final String? color;
  final String? size;
  int quantity;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    this.color,
    this.size,
    this.quantity = 1,
  });

  // 1. تحويل من JSON (للقراءة من التخزين)
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      productId: json['product_id'],
      name: json['name'],
      image: json['image'],
      price: double.parse(json['price'].toString()),
      color: json['color'],
      size: json['size'],
      quantity: json['quantity'],
    );
  }

  // 2. تحويل إلى JSON (للحفظ في التخزين)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'image': image,
      'price': price,
      'color': color,
      'size': size,
      'quantity': quantity,
    };
  }
}