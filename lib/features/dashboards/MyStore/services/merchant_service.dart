import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import '../models/merchant_profile_model.dart';
import '../../../../models/product_model.dart';

class MerchantService {
  final ApiClient _apiClient = ApiClient();

  Future<MerchantProfileModel> getMyStoreProfile() async {
    try {
      // 1️⃣ الخطوة الأهم: جلب الـ ID من بروفايل المستخدم
      // هذا الرابط دائماً يحتوي على ID المستخدم/التاجر
      final userResponse = await _apiClient.get('/users/profile');
      final userId = userResponse.data['id']; // ✅ هنا نحصل على الـ ID الحقيقي

      // 2️⃣ جلب تفاصيل المتجر (الصور والاسم) من الإعدادات
      final settingsResponse = await _apiClient.get('/merchants/settings');
      final settingsData = settingsResponse.data;

      // 3️⃣ جلب المنتجات
      final productsResponse = await _apiClient.get('/merchants/products');
      List<ProductModel> products = [];
      if (productsResponse.data is List) {
        products =
            (productsResponse.data as List)
                .map((p) => ProductModel.fromJson(p))
                .toList();
      }

      // 4️⃣ دمج البيانات في المودل
      return MerchantProfileModel(
        // ✅ نستخدم الـ ID القادم من الخطوة 1
        id: userId ?? 0,

        // ✅ نستخدم باقي البيانات من الخطوة 2 (الإعدادات)
        storeName: settingsData['store_name'] ?? 'متجري',
        bio:
            settingsData['store_description'], // لاحظ الاسم في السيرفر store_description
        // الروابط كما ظهرت في السيرفر
        coverUrl: settingsData['store_banner_url'],
        profileUrl: settingsData['profile_picture_url'],

        // باقي البيانات (قيم افتراضية لأنها غير موجودة في رد الإعدادات)
        location: settingsData['location'] ?? 'غير محدد',
        rating: settingsData['rating'] ?? 0,
        followersCount: settingsData['followers_count'] ?? 0,
        totalSales: 0, // قيمة افتراضية
        // الحسابات المحلية
        activeProductsCount: products.length,
        isVerified: false,
        isDropshipper: false,

        products: products,
      );
    } catch (e) {
      print("❌ Error assembling store profile: $e");
      rethrow;
    }
  }
}
