import 'product_details_model.dart'; // تأكد من استيراد الموديل الذي أنشأناه سابقاً

class CartItemModel {
  final String id; // معرف فريد للعنصر في السلة (يمكن دمجه من id المنتج + id المتغير)
  final ProductDetailsModel product;
  final ProductVariant selectedVariant;
  int quantity;

  CartItemModel({
    required this.id,
    required this.product,
    required this.selectedVariant,
    required this.quantity,
  });

  // حساب السعر الإجمالي لهذا العنصر
  double get totalPrice => selectedVariant.price * quantity;
}