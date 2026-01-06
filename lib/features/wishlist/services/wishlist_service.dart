import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../models/product_model.dart';

class WishlistService {
  final ApiClient _apiClient = ApiClient();

  // جلب قائمة المفضلة
  Future<List<ProductModel>> getWishlist() async {
    try {
      final response = await _apiClient.get('/customer/wishlist');
      // نفترض أن الباك اند يرجع قائمة منتجات داخل مفتاح 'products' أو مباشرة
      final data = response.data;
      if (data is List) {
        return data.map((e) => ProductModel.fromJson(e)).toList();
      } else if (data['products'] is List) {
        return (data['products'] as List)
            .map((e) => ProductModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Wishlist Fetch Error: $e');
      return []; // إرجاع قائمة فارغة في حالة الخطأ
    }
  }

  Future<bool> checkIsWishlisted(String productId) async {
    try {
      // نفس منطق الويب: customer/wishlist/status
      final response = await _apiClient.post('/customer/wishlist/status', data: {
        'productIds': [productId]
      });
      return response.data[productId] == true;
    } catch (e) {
      return false;
    }
  }

  // إضافة للمفضلة
  Future<void> addToWishlist(int productId) async {
    try {
      await _apiClient.post('/customer/wishlist', data: {'productId': productId});
    } catch (e) {
      rethrow;
    }
  }

  // حذف من المفضلة
  Future<void> removeFromWishlist(int productId) async {
    try {
      await _apiClient.delete('/customer/wishlist/$productId');
    } catch (e) {
      rethrow;
    }
  }
}