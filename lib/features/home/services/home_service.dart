import 'package:linyora_project/models/product_model.dart';
import 'package:linyora_project/models/top_user_model.dart';

import '../../../core/api/api_client.dart';
import '../../../models/banner_model.dart';
import '../../../models/category_model.dart';

class HomeService {
  final ApiClient _apiClient = ApiClient();

  // جلب البانرات النشطة
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await _apiClient.get(
        '/browse/main-banners',
      ); // حسب ملف mainBannerController.js
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => BannerModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching banners: $e");
      return [];
    }
  }

  // جلب الأقسام
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get(
        '/categories',
      ); // حسب ملف categoryController.js
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => CategoryModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }

  Future<List<TopUserModel>> getTopModels() async {
    try {
      // - getTopModels
      final response = await _apiClient.get('/browse/top-models');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => TopUserModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching top models: $e");
      return [];
    }
  }

  // جلب أشهر التاجرات
  Future<List<TopUserModel>> getTopMerchants() async {
    try {
      // - getTopMerchants
      final response = await _apiClient.get('/browse/top-merchants');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => TopUserModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching top merchants: $e");
      return [];
    }
  }

  // دالة المتابعة/إلغاء المتابعة
  Future<bool> toggleFollow(int userId) async {
    try {
      await _apiClient.post(
        '/users/$userId/follow',
      ); // تأكد من المسار في routes/userRoutes.js
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<ProductModel>> getProductsByType(String type) async {
    try {
      String endpoint = '';
      switch (type) {
        case 'new':
          endpoint = '/browse/new-arrivals';
          break;
        case 'best':
          endpoint = '/browse/best-sellers';
          break;
        case 'top':
          endpoint = '/browse/top-rated';
          break;
        default:
          return [];
      }

      final response = await _apiClient.get(endpoint);
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => ProductModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching $type products: $e");
      return [];
    }
  }

  // جلب رسائل الشريط الإعلاني
  Future<List<String>> getMarqueeMessages() async {
    try {
      // استبدل هذا بالمسار الصحيح بناءً على الـ BaseURL الخاص بك
      // endpoint: /api/marquee/active
      final response = await _apiClient.get('/marquee/active');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        // تحويل مصفوفة الكائنات إلى مصفوفة نصوص
        // مثال: من [{text: "Hello"}, {text: "World"}] إلى ["Hello", "World"]
        return data.map((item) => item['message_text'].toString()).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching marquee messages: $e");
      return [];
    }
  }
}
