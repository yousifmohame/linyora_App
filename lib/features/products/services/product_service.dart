import 'package:dio/dio.dart';
import 'package:linyora_project/models/product_model.dart';
import '../../../core/api/api_client.dart';
import '../../../models/product_details_model.dart';

class ProductService {
  final ApiClient _apiClient = ApiClient();

  Future<ProductDetailsModel?> getProductDetails(String id) async {
    try {
      final response = await _apiClient.get('/products/$id');
      if (response.statusCode == 200) {
        return ProductDetailsModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching product details: $e');
      rethrow;
    }
  }

  // دالة إضافة للمفضلة
  Future<void> toggleWishlist(int productId, bool isCurrentlyWishlisted) async {
    try {
      if (isCurrentlyWishlisted) {
        await _apiClient.delete('/customer/wishlist/$productId');
      } else {
        await _apiClient.post('/customer/wishlist', data: {'productId': productId});
      }
    } catch (e) {
      rethrow;
    }
  }

  // جلب منتجات مقترحة (بناءً على الفئة أو عشوائي)
  Future<List<ProductModel>> getRelatedProducts(int categoryId) async {
    try {
      // يمكنك تغيير المسار حسب الـ API لديك، مثلاً /products?category_id=$categoryId&limit=4
      final response = await _apiClient.get('/products/$categoryId');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => ProductModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}