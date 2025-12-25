import 'dart:convert'; // ضروري للتعامل مع jsonEncode و jsonDecode
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/cart_item_model.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  static const String _cartKey = 'local_cart_data'; // المفتاح الذي سنخزن فيه البيانات

  // 1. جلب العناصر من التخزين المحلي
  Future<List<CartItemModel>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartString = prefs.getString(_cartKey);

      if (cartString != null) {
        // فك تشفير JSON وتحويله لقائمة
        List<dynamic> decodedList = jsonDecode(cartString);
        return decodedList.map((item) => CartItemModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading cart: $e');
      return [];
    }
  }

  // 2. إضافة منتج للسلة (أو زيادة كميته إذا كان موجوداً)
  Future<void> addToCart(CartItemModel newItem) async {
    final prefs = await SharedPreferences.getInstance();
    List<CartItemModel> currentItems = await getCartItems();

    // التحقق هل المنتج موجود مسبقاً (نفس الـ ID ونفس الخيارات)
    int existingIndex = currentItems.indexWhere((item) => 
        item.productId == newItem.productId && 
        item.color == newItem.color && 
        item.size == newItem.size
    );

    if (existingIndex != -1) {
      // إذا موجود، زود الكمية
      currentItems[existingIndex].quantity += newItem.quantity;
    } else {
      // إذا جديد، أضفه للقائمة
      currentItems.add(newItem);
    }

    // حفظ القائمة الجديدة
    await _saveToStorage(currentItems, prefs);
  }

  // 3. تحديث الكمية
  Future<void> updateQuantity(int productId, int newQty) async {
    final prefs = await SharedPreferences.getInstance();
    List<CartItemModel> currentItems = await getCartItems();

    int index = currentItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      currentItems[index].quantity = newQty;
      await _saveToStorage(currentItems, prefs);
    }
  }

  // 4. حذف عنصر
  Future<void> removeItem(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    List<CartItemModel> currentItems = await getCartItems();

    currentItems.removeWhere((item) => item.productId == productId);
    await _saveToStorage(currentItems, prefs);
  }

  // 5. تفريغ السلة (عند إتمام الطلب)
  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  // دالة مساعدة للحفظ
  Future<void> _saveToStorage(List<CartItemModel> items, SharedPreferences prefs) async {
    // تحويل القائمة إلى نص JSON
    String encodedList = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString(_cartKey, encodedList);
  }
}