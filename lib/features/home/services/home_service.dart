import 'package:flutter/material.dart';
import 'package:linyora_project/core/api/api_client.dart'; // تأكد من المسار
import 'package:linyora_project/models/notification_model.dart';
import 'package:linyora_project/models/product_model.dart';
import 'package:linyora_project/models/top_user_model.dart';
import 'package:linyora_project/models/banner_model.dart';
import 'package:linyora_project/models/category_model.dart';

class HomeService {
  // استخدام الكلاس المخصص الذي يحتوي على Interceptor للتوكن
  final ApiClient _apiClient = ApiClient();

  // 1. جلب البانرات
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await _apiClient.get('/browse/main-banners');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => BannerModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching banners: $e");
      return [];
    }
  }

  // 2. جلب الأقسام
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get('/categories');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => CategoryModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      return [];
    }
  }

  // 3. جلب أشهر العارضات
  Future<List<TopUserModel>> getTopModels() async {
    try {
      final response = await _apiClient.get('/browse/top-models');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => TopUserModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching top models: $e");
      return [];
    }
  }

  // 4. جلب أشهر التاجرات
  Future<List<TopUserModel>> getTopMerchants() async {
    try {
      final response = await _apiClient.get('/browse/top-merchants');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => TopUserModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching top merchants: $e");
      return [];
    }
  }

  // 5. المتابعة/إلغاء المتابعة
  // ملاحظة: الـ ApiClient سيقوم بإرفاق التوكن تلقائياً وهذا ضروري هنا
  Future<bool> toggleFollow(int userId) async {
    try {
      await _apiClient.post('/users/$userId/follow');
      return true;
    } catch (e) {
      debugPrint("Error toggling follow: $e");
      return false;
    }
  }

  // 6. جلب المنتجات حسب النوع
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
      debugPrint("Error fetching $type products: $e");
      return [];
    }
  }

  // 7. جلب رسائل الشريط الإعلاني
  Future<List<String>> getMarqueeMessages() async {
    try {
      final response = await _apiClient.get('/marquee/active');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => item['message_text'].toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching marquee messages: $e");
      return [];
    }
  }

  // ✅ دالة جديدة: جلب سرعة الشريط
  Future<int> getMarqueeSpeed() async {
    try {
      final response = await _apiClient.get('/settings/marquee_speed');
      // نفترض أن الباك إند يرجع رقم مباشرة أو نص يحتوي على رقم
      return int.tryParse(response.data.toString()) ?? 20;
    } catch (e) {
      return 20; // القيمة الافتراضية
    }
  }

  // ✅ دالة جديدة: جلب لون الخلفية
  Future<String> getMarqueeColor() async {
    try {
      final response = await _apiClient.get('/settings/marquee_bg_color');
      return response.data.toString(); // يرجع سترينج مثل "#000000"
    } catch (e) {
      return "#000000"; // القيمة الافتراضية (أسود)
    }
  }

  // 8. البحث عن المنتجات
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      // استخدام queryParameters مع ApiClient
      final response = await _apiClient.get(
        '/products/search',
        queryParameters: {'term': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Search error: $e");
      return [];
    }
  }

  // 9. جلب الإشعارات (محمية بالتوكن)
  Future<List<NotificationModel>> getNotifications() async {
    try {
      // الـ ApiClient سيضيف التوكن تلقائياً في الهيدر
      final response = await _apiClient.get('/notifications');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      return [];
    }
  }

  // 10. تحديد كل الإشعارات كمقروءة (محمية بالتوكن)
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await _apiClient.post('/notifications/read');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error marking all as read: $e");
      return false;
    }
  }
}
