import 'package:linyora_project/features/browse/models/model_profile_details.dart';
import '../../../core/api/api_client.dart';
import '../models/browsed_model.dart';
import 'dart:convert'; // لإستخدام jsonEncode للطباعة بشكل مقروء

class BrowseService {
  final ApiClient _apiClient = ApiClient();

  // جلب قائمة المودلز
  Future<List<BrowsedModel>> getModels() async {
    try {
      print('\n🔵 === START DEBUG: Fetching Models ===');

      final response = await _apiClient.get('/browse/models');

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // ✅ 1. طباعة البيانات الخام بشكل منظم
        try {
          // نقوم بترميز البيانات كـ JSON نصي منسق ليسهل قراءته في الكونسول
          String prettyJson = const JsonEncoder.withIndent(
            '  ',
          ).convert(response.data);
          print('📦 Raw Data from Backend:\n$prettyJson');
        } catch (e) {
          print('⚠️ Could not print pretty JSON: $e');
          print('📦 Raw Data (Unformatted): ${response.data}');
        }

        print('🔄 Starting Parsing...');

        // ✅ 2. محاولة التحويل مع التقاط الأخطاء لكل عنصر
        List<BrowsedModel> models = [];
        List<dynamic> dataList = response.data as List;

        for (var i = 0; i < dataList.length; i++) {
          try {
            models.add(BrowsedModel.fromJson(dataList[i]));
          } catch (e) {
            print('❌ Error parsing item at index [$i]:');
            print('   Data: ${dataList[i]}');
            print('   Error: $e');
          }
        }

        print(
          '✅ Parsing Complete. Success: ${models.length} / Total: ${dataList.length}',
        );
        print('🔵 === END DEBUG ===\n');

        return models;
      }

      print('❌ Failed to fetch models: ${response.statusCode}');
      return [];
    } catch (e) {
      print("❌ Error fetching models: $e");
      return [];
    }
  }

  // --- التعديل الرئيسي هنا (جلب التفاصيل والباقات) ---
  // استبدل الدالة القديمة بهذه الدالة الجديدة للتشخيص
  Future<Map<String, dynamic>> getModelDetails(int id) async {
    print('\n================ DEBUG START: getModelDetails ================');
    try {
      final response = await _apiClient.get('/browse/models/$id');

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Raw Data Fetched Successfully');

        // 1. اختبار تحويل البروفايل (Profile Parsing Test)
        try {
          if (data['profile'] != null) {
            print('Testing Profile Parsing...');
            // نقوم بمحاولة تحويل مبدئية لنرى هل سينجح أم لا
            ModelFullProfile.fromJson(data['profile']);
            print('✅ Profile Parsed Successfully');
          } else {
            print('⚠️ Warning: Profile key is null');
          }
        } catch (e, s) {
          print('❌ CRITICAL ERROR IN PROFILE PARSING: $e');
          print('Stack: $s');
          // غالباً الخطأ هنا، ربما حقل stats أو portfolio ناقص
        }

        // 2. اختبار تحويل الباقات (Packages Parsing Test)
        try {
          if (data['packages'] != null) {
            print(
              'Testing Packages Parsing (Count: ${(data['packages'] as List).length})...',
            );
            List<dynamic> pkgs = data['packages'];
            for (var i = 0; i < pkgs.length; i++) {
              try {
                ServicePackage.fromJson(pkgs[i]);
                print('✅ Package [$i] Parsed OK');
              } catch (e) {
                print('❌ ERROR Parsing Package [$i]: $e');
                print('Bad Data: ${pkgs[i]}');
              }
            }
          }
        } catch (e) {
          print('❌ General Error in Packages List: $e');
        }

        return data;
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ FETCH ERROR: $e');
      throw Exception('خطأ في الاتصال: $e');
    } finally {
      print('================ DEBUG END ================\n');
    }
  }

  // جلب منتجات التاجر
  Future<List<MerchantProduct>> getMerchantProducts() async {
    try {
      final response = await _apiClient.get('/merchants/products');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => MerchantProduct.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching merchant products: $e");
      return [];
    }
  }

  // إنشاء رابط الدفع
  Future<String?> createAgreementSession({
    required int modelId,
    required String productId,
    int? offerId,
    int? packageTierId,
  }) async {
    try {
      print('Creating session for Model: $modelId, Product: $productId');
      final response = await _apiClient.post(
        '/payments/create-agreement-checkout-session',
        data: {
          'model_id': modelId,
          'product_id': productId,
          if (offerId != null) 'offer_id': offerId,
          if (packageTierId != null) 'package_tier_id': packageTierId,
        },
      );
      print('Session created: ${response.data}');
      return response.data['url'];
    } catch (e) {
      print('Payment Session Error: $e');
      throw Exception('فشل إنشاء جلسة الدفع');
    }
  }
}
