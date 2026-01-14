import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
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

  // --- دوال التاجر (Merchant Methods) ---

  Future<String> _uploadImage(File file) async {
    try {
      String fileName = file.path.split('/').last;

      // نحدد نوع الملف يدوياً لتجنب مشاكل الاستنتاج
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType(
            'image',
            'jpeg',
          ), // افتراض JPEG أو يمكن استنتاجه
        ),
      });

      // إرسال الطلب مع تحديد الهيدر يدوياً لهذا الطلب فقط
      final response = await _apiClient.post(
        '/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data', // ✅ إجبار النوع
        ),
      );

      return response.data['imageUrl'];
    } catch (e) {
      print("Upload Error Details: $e");
      throw Exception('فشل رفع الصورة: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 2. وظائف إدارة المنتجات (التاجر)
  // ---------------------------------------------------------------------------

  // جلب منتجات التاجر
  Future<List<ProductModel>> getMyProducts() async {
    try {
      final response = await _apiClient.get('/merchants/products');
      List<dynamic> dataList = [];
      if (response.data is List) {
        dataList = response.data;
      } else if (response.data is Map) {
        dataList = response.data['data'] ?? response.data['products'] ?? [];
      }
      return dataList.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw e.toString();
    }
  }

  // إضافة منتج جديد (Process: Upload Images -> Send JSON)
  Future<bool> createProduct(
    Map<String, dynamic> productData,
    List<File> images,
  ) async {
    try {
      // أ) رفع الصور والحصول على الروابط
      List<String> uploadedUrls = [];
      for (var img in images) {
        String url = await _uploadImage(img);
        uploadedUrls.add(url);
      }

      // ب) دمج الروابط في هيكل البيانات
      // نقوم بإنشاء نسخة جديدة من البيانات لتجنب تعديل الأصل
      Map<String, dynamic> finalData = Map.from(productData);

      List<dynamic> variants = List.from(finalData['variants'] ?? []);
      if (variants.isNotEmpty) {
        // إضافة الصور للمتغير الأول (أو توزيعها حسب منطق الواجهة)
        Map<String, dynamic> firstVariant = Map.from(variants[0]);
        firstVariant['images'] = uploadedUrls;
        variants[0] = firstVariant;
        finalData['variants'] = variants;
      }

      // ج) إرسال البيانات كـ JSON String صريح
      // ✅ نستخدم Options لتحديد النوع كـ JSON وإجبار Dio على عدم استخدام FormData
      final response = await _apiClient.post(
        '/merchants/products',
        data: jsonEncode(finalData),
        options: Options(
          contentType: 'application/json', // ✅ حل جذري لمشكلة النوع
          headers: {'Accept': 'application/json'},
        ),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        print("Create Product API Error: ${e.response?.data}");
        print("Status Code: ${e.response?.statusCode}");
        throw e.response?.data['message'] ?? 'فشل إضافة المنتج';
      }
      throw e.toString();
    }
  }

  // تعديل منتج
  Future<bool> updateProduct(
    String id,
    Map<String, dynamic> productData, {
    List<File>? newImages,
  }) async {
    try {
      Map<String, dynamic> finalData = Map.from(productData);

      // أ) رفع الصور الجديدة إن وجدت
      if (newImages != null && newImages.isNotEmpty) {
        List<String> newUrls = [];
        for (var img in newImages) {
          String url = await _uploadImage(img);
          newUrls.add(url);
        }

        List<dynamic> variants = List.from(finalData['variants'] ?? []);
        if (variants.isNotEmpty) {
          Map<String, dynamic> firstVariant = Map.from(variants[0]);
          List<String> currentImages = List<String>.from(
            firstVariant['images'] ?? [],
          );
          currentImages.addAll(newUrls);

          firstVariant['images'] = currentImages;
          variants[0] = firstVariant;
          finalData['variants'] = variants;
        }
      }

      // ب) إرسال التحديث
      final response = await _apiClient.put(
        '/merchants/products/$id',
        data: jsonEncode(finalData),
        options: Options(
          contentType: 'application/json', // ✅ حل جذري
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        print("Update Product API Error: ${e.response?.data}");
        throw e.response?.data['message'] ?? 'فشل تحديث المنتج';
      }
      throw e.toString();
    }
  }

  // حذف منتج
  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _apiClient.delete('/merchants/products/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<List<PromotionTier>> getPromotionTiers() async {
    try {
      final response = await _apiClient.get('/merchants/promotion-tiers');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => PromotionTier.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching tiers: $e');
      return [];
    }
  }

  // جلب تفاصيل منتج واحد (يحتوي على تفاصيل الدروب شيبينج الدقيقة)
  Future<ProductModel?> getProductById(int id) async {
    try {
      // ✅ هذا الرابط يستدعي الدالة getProductById في الباك إند
      final response = await _apiClient.get('/products/$id'); 
      
      if (response.statusCode == 200 && response.data != null) {
        // تحويل البيانات باستخدام المودل الذي قمنا بتحديثه
        return ProductModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching single product: $e');
      return null;
    }
  }

  // بدء عملية الترويج (إنشاء رابط دفع)
  Future<String?> promoteProduct(int productId, int tierId) async {
    try {
      final response = await _apiClient.post(
        '/merchants/products/$productId/promote',
        data: {'tierId': tierId},
      );
      return response.data['checkoutUrl'];
    } catch (e) {
      throw Exception('فشل إنشاء رابط الدفع');
    }
  }
}

class PromotionTier {
  final int id;
  final String name;
  final int durationDays;
  final double price;

  PromotionTier({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
  });

  factory PromotionTier.fromJson(Map<String, dynamic> json) {
    return PromotionTier(
      id: json['id'],
      name: json['name'],
      durationDays: json['duration_days'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}
