import 'dart:io';
import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/supplier/products/models/supplier_models.dart';


class SupplierProductsService {
  final ApiClient _apiClient = ApiClient();

  // جلب المنتجات
  Future<List<SupplierProduct>> getProducts() async {
    try {
      final response = await _apiClient.get('/supplier/products');
      return (response.data as List).map((e) => SupplierProduct.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل جلب المنتجات');
    }
  }

  // جلب التصنيفات (الشجرة)
  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.get('/categories');
      // التعامل مع الهيكل سواء كان مصفوفة مباشرة أو داخل data
      final list = (response.data is List) ? response.data : response.data['data'];
      return (list as List).map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // رفع صورة (تماماً مثل React)
  Future<String> uploadImage(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiClient.post('/upload', data: formData);
      return response.data['imageUrl']; // تأكد من اسم الحقل في السيرفر
    } catch (e) {
      throw Exception('فشل رفع الصورة');
    }
  }

  // حفظ المنتج (إضافة أو تعديل)
  Future<void> saveProduct(SupplierProduct product) async {
    try {
      if (product.id != null) {
        await _apiClient.put('/supplier/products/${product.id}', data: product.toJson());
      } else {
        await _apiClient.post('/supplier/products', data: product.toJson());
      }
    } catch (e) {
      throw Exception('فشل حفظ المنتج');
    }
  }

  // حذف المنتج
  Future<void> deleteProduct(int id) async {
    await _apiClient.delete('/supplier/products/$id');
  }
}