import 'package:linyora_project/models/product_model.dart';

import '../../../core/api/api_client.dart';
import '../../../models/section_model.dart';

class SectionService {
  final ApiClient _apiClient = ApiClient();

  Future<List<SectionModel>> getActiveSections() async {
    try {
      final response = await _apiClient.get('/sections/active'); //

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => SectionModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching sections: $e");
      return [];
    }
  }

  Future<SectionModel?> getSectionById(int id) async {
    try {
      final response = await _apiClient.get('/sections/$id');
      return SectionModel.fromJson(response.data);
    } catch (e) {
      print("Error fetching section details: $e");
      return null;
    }
  }

  // 2. جلب المنتجات بناء على مصفوفة Category IDs
  Future<List<ProductModel>> getProductsByCategories(
    List<int> categoryIds,
  ) async {
    if (categoryIds.isEmpty) return [];

    try {
      final response = await _apiClient.get(
        '/products',
        queryParameters: {'category_ids': categoryIds.join(','), 'limit': 50},
      );

      print(
        "Products API Response Type: ${response.data.runtimeType}",
      ); // للتأكد في الكونسول

      final dynamic rawData = response.data;
      List<dynamic> targetList = [];

      // 1. إذا كان الرد عبارة عن قائمة مباشرة (وهذا سبب الخطأ السابق لديك)
      if (rawData is List) {
        targetList = rawData;
      }
      // 2. إذا كان كائناً (Map) ويحتوي على مفتاح products
      else if (rawData is Map<String, dynamic>) {
        if (rawData.containsKey('products') && rawData['products'] is List) {
          targetList = rawData['products'];
        } else if (rawData.containsKey('data') && rawData['data'] is List) {
          targetList = rawData['data'];
        }
      }

      return targetList.map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching section products: $e");
      return [];
    }
  }
}
