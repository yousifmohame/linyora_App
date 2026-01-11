import '../../../core/api/api_client.dart';
import '../models/supplier_product_model.dart';

class DropshippingService {
  final ApiClient _apiClient = ApiClient();

  // جلب منتجات الموردين
  Future<List<SupplierProduct>> getSupplierProducts() async {
    try {
      final response = await _apiClient.get('/dropshipping/supplier-products');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => SupplierProduct.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching dropshipping products: $e");
      throw Exception('فشل جلب المنتجات');
    }
  }

  // استيراد منتج للمتجر
  Future<void> importProduct(int supplierProductId, double salePrice) async {
    try {
      final response = await _apiClient.post(
        '/dropshipping/import-product',
        data: {
          'supplierProductId': supplierProductId,
          'salePrice': salePrice,
        },
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('فشل الاستيراد');
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء استيراد المنتج');
    }
  }
}