import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../models/checkout_models.dart';
import '../../../models/cart_item_model.dart';

class CheckoutService {
  final ApiClient _apiClient = ApiClient();

  // 1. جلب العناوين
  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _apiClient.get('/users/addresses');
      return (response.data as List)
          .map((e) => AddressModel.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching addresses: $e');
      return [];
    }
  }

  // 2. جلب خيارات الشحن لمجموعة منتجات
  Future<List<ShippingOption>> getShippingOptions(List<int> productIds) async {
    try {
      final response = await _apiClient.post(
        '/products/shipping-options-for-cart',
        data: {'productIds': productIds},
      );
      return (response.data as List)
          .map((e) => ShippingOption.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching shipping: $e');
      return [];
    }
  }

  // 3. إرسال الطلب (COD - الدفع عند الاستلام)
  Future<void> placeCodOrder({
    required List<CartItemModel> cartItems,
    required int addressId,
    required List<Map<String, dynamic>> shippingSelections,
    required double shippingCost,
  }) async {
    try {
      await _apiClient.post(
        '/orders/create-cod',
        data: {
          'cartItems':
              cartItems
                  .map(
                    (item) => {
                      'id': item.selectedVariant.id, // variant_id
                      'productId': item.product.id,
                      'quantity': item.quantity,
                      'price': item.selectedVariant.price,
                      // أضف الحقول الأخرى إذا لزم الأمر مثل merchantId
                    },
                  )
                  .toList(),
          'shippingAddressId': addressId,
          'merchant_shipping_selections': shippingSelections,
          'shipping_cost': shippingCost,
        },
      );
    } on DioException catch (e) {
      // طباعة تفاصيل الخطأ القادم من السيرفر
      print("Server Error Details: ${e.response?.data}");
      rethrow;
    }
  }
}
