import '../../../core/api/api_client.dart';
import '../../../models/promoted_product_model.dart';

class TrendsService {
  final ApiClient _apiClient = ApiClient();

  Future<List<PromotedProductModel>> getPromotedProducts() async {
    try {
      // الرابط يطابق الروت في الباك إند
      final response = await _apiClient.get('/browse/trends');
      
      // البيانات تأتي مصفوفة مباشرة حسب كود الـ Controller
      final List data = response.data; 
      
      return data.map((e) => PromotedProductModel.fromJson(e)).toList();
    } catch (e) {
      print("Trends Error: $e");
      throw e;
    }
  }
}