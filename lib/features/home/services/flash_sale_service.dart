import '../../../core/api/api_client.dart';
import '../../../models/flash_sale_model.dart';

class FlashSaleService {
  final ApiClient _apiClient = ApiClient();

  Future<List<FlashSaleCampaign>> getActiveFlashSales() async {
    try {
      final response = await _apiClient.get('/flash-sale/active'); //
      
      if (response.statusCode == 200) {
        // الـ API قد يعيد مصفوفة أو كائناً، يجب التحقق
        if (response.data is List) {
          return (response.data as List)
              .map((e) => FlashSaleCampaign.fromJson(e))
              .toList();
        } 
        // حالة نادرة: قد يعيد كائناً مفرداً إذا كان هناك عرض واحد (حسب الباك إند)
        else if (response.data != null) {
           return [FlashSaleCampaign.fromJson(response.data)];
        }
      }
      return [];
    } catch (e) {
      print("Error fetching flash sales: $e");
      return [];
    }
  }
}