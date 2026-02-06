import 'package:linyora_project/models/product_details_model.dart';

import 'product_model.dart'; // ✅ 1. استيراد المودل العام للمنتجات

class CartItemModel {
  final String id; 
  final ProductModel product; // ✅ 2. تغيير النوع ليقبل أي منتج (من القائمة أو التفاصيل)
  final ProductVariant? selectedVariant; // ✅ 3. جعله اختيارياً (قد يكون null للمنتجات البسيطة)
  int quantity;

  CartItemModel({
    required this.id,
    required this.product,
    this.selectedVariant, // ✅ لم يعد required
    required this.quantity,
  });

  // حساب السعر الإجمالي لهذا العنصر
  double get totalPrice {
    // ✅ إذا كان هناك متغير (variant) نأخذ سعره، وإلا نأخذ سعر المنتج الأصلي
    double price = selectedVariant?.price ?? product.price;
    return price * quantity;
  }
}