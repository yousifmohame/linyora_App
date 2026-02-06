import 'package:flutter/material.dart';
import 'package:linyora_project/models/product_details_model.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/product_model.dart'; // ✅ 1. استيراد مودل المنتج العام
// import '../../../models/product_details_model.dart'; // يمكن الاستغناء عنه أو إبقاؤه حسب الحاجة

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => _items;

  // الحصول على إجمالي السعر
  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // الحصول على عدد العناصر
  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // ✅ دالة الإضافة للسلة (تم التعديل لتكون مرنة)
  // 1. تقبل ProductModel بدلاً من ProductDetailsModel
  // 2. تقبل variant كقيمة اختيارية (Nullable)
  // 3. تم تعديل الترتيب ليناسب استدعاء ProductCard
  void addToCart(ProductModel product, int quantity, ProductVariant? variant) {
    // نتحقق مما إذا كان المنتج موجوداً مسبقاً (مع نفس المتغير إن وجد)
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedVariant?.id == variant?.id,
    ); // ✅ مقارنة آمنة للـ Null

    if (existingIndex >= 0) {
      // إذا كان موجوداً، نزيد الكمية
      _items[existingIndex].quantity += quantity;
    } else {
      // ✅ تكوين ID فريد (مع مراعاة أن variant قد يكون null)
      final String uniqueId =
          variant != null
              ? '${product.id}_${variant.id}'
              : '${product.id}_base';

      // إذا لم يكن موجوداً، نضيفه كعنصر جديد
      _items.add(
        CartItemModel(
          id: uniqueId,
          product: product, // يجب أن يقبل CartItemModel هذا النوع
          selectedVariant: variant, // قد يكون null
          quantity: quantity,
        ),
      );
    }

    notifyListeners(); // تحديث الواجهة
  }

  // دالة حذف عنصر
  void removeFromCart(String cartItemId) {
    _items.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  // دالة تحديث الكمية
  void updateQuantity(String cartItemId, int newQuantity) {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      if (newQuantity > 0) {
        _items[index].quantity = newQuantity;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // تفريغ السلة
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
