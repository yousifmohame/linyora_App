import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../services/wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _service = WishlistService();

  List<ProductModel> _items = [];
  final Set<int> _itemIds = {};

  // ✅ متغير صريح للتحميل
  bool _isLoading = false;

  List<ProductModel> get items => _items;
  bool get isLoading => _isLoading;

  bool isWishlisted(int productId) {
    return _itemIds.contains(productId);
  }

  // تحميل المفضلة
  Future<void> fetchWishlist() async {
    // تجنب التحميل المتكرر إذا كانت البيانات موجودة بالفعل (اختياري)
    // if (_items.isNotEmpty) return;

    _isLoading = true;
    // notifyListeners(); // يمكن تفعيل هذا السطر إذا أردت إظهار لودينج عند كل تحديث

    try {
      final products = await _service.getWishlist();
      _items = products;
      _itemIds.clear();
      _itemIds.addAll(products.map((e) => e.id));
    } catch (e) {
      debugPrint("Error fetching wishlist: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تبديل الحالة
  Future<void> toggleWishlist(ProductModel product) async {
    final isLiked = _itemIds.contains(product.id);

    // 1. تحديث فوري للواجهة (Optimistic UI)
    if (isLiked) {
      _items.removeWhere((p) => p.id == product.id);
      _itemIds.remove(product.id);
    } else {
      _items.add(product);
      _itemIds.add(product.id);
    }
    notifyListeners();

    // 2. إرسال للسيرفر
    try {
      if (isLiked) {
        await _service.removeFromWishlist(product.id);
      } else {
        await _service.addToWishlist(product.id);
      }
    } catch (e) {
      // 3. التراجع عند الخطأ
      if (isLiked) {
        _items.add(product);
        _itemIds.add(product.id);
      } else {
        _items.removeWhere((p) => p.id == product.id);
        _itemIds.remove(product.id);
      }
      notifyListeners();
      debugPrint("Wishlist Error: $e");
    }
  }
}
