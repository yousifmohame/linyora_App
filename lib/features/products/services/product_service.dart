import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:linyora_project/models/filter_options_model.dart';
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
    int limit = 20,
    // إضافة هذا المعامل لاستقبال الفلاتر من واجهة المستخدم
    Map<String, dynamic>? filters,
  }) async {
    try {
      // 1. الإعدادات الأساسية
      final Map<String, dynamic> queryParams = {'limit': limit};

      // 2. إضافة المعرفات المباشرة إذا وجدت
      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      } else if (merchantId != null) {
        queryParams['merchant_id'] = merchantId;
      }

      // 3. دمج فلاتر البحث والترتيب (السعر، الماركة، الترتيب)
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            // معالجة القوائم (مثل الماركات) لتحويلها لنص مفصول بفواصل
            if (value is List) {
              if (value.isNotEmpty) {
                queryParams[key] = value.join(',');
              }
            } else {
              queryParams[key] = value;
            }
          }
        });
      }

      // 4. استدعاء API
      final response = await _apiClient.get(
        '/products',
        queryParameters: queryParams,
      );

      // 5. معالجة البيانات (الكود الخاص بك)
      List<dynamic> dataList = [];

      // التحقق مما إذا كانت البيانات تأتي كقائمة مباشرة
      if (response.data is List) {
        dataList = response.data;
      }
      // أو إذا كانت تأتي داخل مفتاح 'data'
      else if (response.data is Map && response.data['data'] is List) {
        dataList = response.data['data'];
      }
      // حالة إضافية للاحتياط (بعض السيرفرات تعيد products)
      else if (response.data is Map && response.data['products'] is List) {
        dataList = response.data['products'];
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

  Future<FilterOptionsModel> getFilterOptions() async {
    try {
      final response = await _apiClient.get('/products/filters');
      return FilterOptionsModel.fromJson(response.data);
    } catch (e) {
      debugPrint("Error fetching filters: $e");
      // إرجاع موديل فارغ في حال الخطأ لعدم تعطيل الواجهة
      return FilterOptionsModel();
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
