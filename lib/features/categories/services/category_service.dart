import 'package:flutter/foundation.dart';
import 'package:linyora_project/models/product_model.dart';
import '../../../core/api/api_client.dart';
import '../../../models/category_model.dart';

class CategoryDetailsResponse {
  final String categoryName;
  final List<ProductModel> products;
  final List<CategoryModel> subcategories;

  CategoryDetailsResponse({
    required this.categoryName,
    required this.products,
    required this.subcategories,
  });
}

class CategoryService {
  // استخدام الـ Singleton (اختياري، يمكنك استخدام Provider)
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<List<CategoryModel>> getAllCategories() async {
    try {
      // بناءً على ملف categoryRoutes.js، الرابط هو / (إذا كان الراوت مركب على /categories)
      // أو /browse/categories كما في الموقع
      final response = await _apiClient.get('/categories'); 
      
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((e) => CategoryModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  Future<CategoryDetailsResponse?> getCategoryProducts(String slug) async {
    try {
      // الاتصال بالمسار الذي حددته في الباك إند
      final response = await _apiClient.get('/categories/$slug/products');
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // 1. تحويل المنتجات
        List<ProductModel> products = [];
        if (data['products'] != null) {
          products = (data['products'] as List)
              .map((e) => ProductModel.fromJson(e))
              .toList();
        }

        // 2. تحويل الأقسام الفرعية
        List<CategoryModel> subcategories = [];
        if (data['subcategories'] != null) {
          subcategories = (data['subcategories'] as List)
              .map((e) => CategoryModel.fromJson(e))
              .toList();
        }

        return CategoryDetailsResponse(
          categoryName: data['categoryName'] ?? '',
          products: products,
          subcategories: subcategories,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching category products: $e');
      return null;
    }
  }
}