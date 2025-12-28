import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../services/wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _service = WishlistService();
  
  // قائمة المنتجات المفضلة
  List<ProductModel> _items = [];
  // مجموعة IDs للبحث السريع (O(1))
  final Set<int> _itemIds = {};

  List<ProductModel> get items => _items;
  bool get isLoading => _items.isEmpty && _itemIds.isEmpty; // منطق بسيط للتحميل

  // التحقق هل المنتج في المفضلة
  bool isWishlisted(int productId) {
    return _itemIds.contains(productId);
  }

  // تحميل المفضلة عند فتح التطبيق
  Future<void> fetchWishlist() async {
    final products = await _service.getWishlist();
    _items = products;
    _itemIds.clear();
    _itemIds.addAll(products.map((e) => e.id));
    notifyListeners();
  }

  // تبديل الحالة (Add/Remove)
  Future<void> toggleWishlist(ProductModel product) async {
    final isLiked = _itemIds.contains(product.id);

    // 1. تحديث الواجهة فوراً (Optimistic Update)
    if (isLiked) {
      _items.removeWhere((p) => p.id == product.id);
      _itemIds.remove(product.id);
    } else {
      _items.add(product);
      _itemIds.add(product.id);
    }
    notifyListeners();

    // 2. إرسال الطلب للسيرفر
    try {
      if (isLiked) {
        await _service.removeFromWishlist(product.id);
      } else {
        await _service.addToWishlist(product.id);
      }
    } catch (e) {
      // 3. التراجع في حالة الخطأ
      if (isLiked) {
        _items.add(product);
        _itemIds.add(product.id);
      } else {
        _items.removeWhere((p) => p.id == product.id);
        _itemIds.remove(product.id);
      }
      notifyListeners();
      // يمكن عرض SnackBar هنا إذا كنت تمرر Context
      print("Error updating wishlist: $e");
    }
  }
}