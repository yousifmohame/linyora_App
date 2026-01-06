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

  Future<List<ProductDetailsModel>> getProducts({
    int? categoryId,
    int? merchantId,
    int limit = 6,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'limit': limit};

      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      } else if (merchantId != null) {
        queryParams['merchant_id'] = merchantId;
      }

      final response = await _apiClient.get(
        '/products',
        queryParameters: queryParams,
      );

      // --- التصحيح هنا ---
      List<dynamic> dataList = [];

      // التحقق مما إذا كانت البيانات تأتي كقائمة مباشرة (وهذا هو الحال في مشروعك)
      if (response.data is List) {
        dataList = response.data;
      }
      // أو إذا كانت تأتي داخل مفتاح 'data' (للاحتياط)
      else if (response.data is Map && response.data['data'] is List) {
        dataList = response.data['data'];
      }

      return dataList.map((e) => ProductDetailsModel.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  // دالة إضافة للمفضلة
  Future<void> toggleWishlist(int productId, bool isCurrentlyWishlisted) async {
    try {
      if (isCurrentlyWishlisted) {
        await _apiClient.delete('/customer/wishlist/$productId');
      } else {
        await _apiClient.post(
          '/customer/wishlist',
          data: {'productId': productId},
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // جلب منتجات مقترحة (بناءً على الفئة أو عشوائي)
  Future<List<ProductDetailsModel>> getRelatedProducts(
    String categoryId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/products',
        queryParameters: {'category_id': categoryId, 'limit': 20},
      );
      return (response.data['data'] as List)
          .map((e) => ProductDetailsModel.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
