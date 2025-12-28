import 'package:flutter/material.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/product_details_model.dart';

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

  // دالة الإضافة للسلة
  void addToCart(ProductDetailsModel product, ProductVariant variant, int quantity) {
    // نتحقق مما إذا كان المنتج بهذا المتغير (اللون/المقاس) موجوداً بالفعل
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.selectedVariant.id == variant.id
    );

    if (existingIndex >= 0) {
      // إذا كان موجوداً، نزيد الكمية فقط
      _items[existingIndex].quantity += quantity;
    } else {
      // إذا لم يكن موجوداً، نضيفه كعنصر جديد
      _items.add(CartItemModel(
        id: '${product.id}_${variant.id}', // تكوين ID فريد
        product: product,
        selectedVariant: variant,
        quantity: quantity,
      ));
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
        // إذا الكمية 0 نحذف العنصر
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