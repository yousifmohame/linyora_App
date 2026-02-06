import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/api/api_client.dart';
import '../../../models/checkout_models.dart';
import '../../../models/cart_item_model.dart';

class CheckoutService {
  final ApiClient _apiClient = ApiClient();

  // 1. جلب العناوين
  Future<List<AddressModel>> getAddresses() async {
    try {
      final response = await _apiClient.get('/users/addresses');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => AddressModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching addresses: $e');
      return [];
    }
  }
  // 3. جلب خيارات الشحن
  Future<List<ShippingOption>> getShippingOptions(List<int> productIds) async {
    try {
      final response = await _apiClient.post(
        '/products/shipping-options-for-cart',
        data: {'productIds': productIds},
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => ShippingOption.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("❌ Error fetching shipping: $e");
      return [];
    }
  }

  // 4. الدفع بالبطاقة (Stripe)
  Future<void> placeCardOrder({
    required List<CartItemModel> cartItems,
    required int addressId,
    required List<Map<String, dynamic>> shippingSelections,
    required double shippingCost,
    required double totalAmount,
    required String paymentMethodId,
  }) async {
    try {
      // ✅ استخدام الدالة المساعدة لتجهيز البيانات بشكل آمن
      final itemsPayload = _buildCartItemsPayload(cartItems);

      final orderPayload = {
        'cartItems': itemsPayload,
        'shippingAddressId': addressId,
        'shipping_cost': shippingCost,
        'total_amount': totalAmount,
        'merchant_shipping_selections': shippingSelections,
      };

      // إنشاء PaymentIntent
      final intentResponse = await _apiClient.post(
        '/payments/create-intent',
        data: {
          'amount': totalAmount,
          'currency': 'sar',
          'payment_method_id': paymentMethodId,
          'merchant_id': cartItems.isNotEmpty ? cartItems.first.product.merchantId : null,
          ...orderPayload,
        },
      );

      final String clientSecret = intentResponse.data['clientSecret'];
      final String paymentIntentId = intentResponse.data['id'] ??
          intentResponse.data['paymentIntentId'] ??
          clientSecret.split('_secret')[0];

      // تأكيد الدفع عبر Stripe
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(
            paymentMethodId: paymentMethodId,
          ),
        ),
      );

      // حفظ الطلب في الباك إند
      await _apiClient.post(
        '/orders/create-from-intent',
        data: {'paymentIntentId': paymentIntentId, ...orderPayload},
      );
    } on StripeException catch (e) {
      throw Exception(e.error.localizedMessage ?? "فشلت عملية الدفع");
    } catch (e) {
      throw _handleError(e);
    }
  }

  // 5. الدفع عند الاستلام (COD)
  Future<void> placeCodOrder({
    required List<CartItemModel> cartItems,
    required int addressId,
    required List<Map<String, dynamic>> shippingSelections,
    required double shippingCost,
    required double totalAmount,
  }) async {
    try {
      // ✅ استخدام نفس الدالة المساعدة
      final itemsPayload = _buildCartItemsPayload(cartItems);

      final orderPayload = {
        'cartItems': itemsPayload,
        'shippingAddressId': addressId,
        'shipping_cost': shippingCost,
        'total_amount': totalAmount,
        'merchant_shipping_selections': shippingSelections,
      };

      await _apiClient.post('/orders/create-cod', data: orderPayload);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- دوال مساعدة (Private Helpers) ---

  // ✅ دالة لتجهيز بيانات المنتجات بشكل آمن (تحل مشكلة Null Safety)
  List<Map<String, dynamic>> _buildCartItemsPayload(List<CartItemModel> cartItems) {
    return cartItems.map((item) {
      // السعر: إذا وجد للمتغير سعر نأخذه، وإلا نأخذ سعر المنتج
      final double price = item.selectedVariant?.price ?? item.product.price;
      
      // معرف المتغير: قد يكون null
      final int? variantId = item.selectedVariant?.id;

      return {
        'product_id': item.product.id,
        'productId': item.product.id, // للتوافق
        
        'variant_id': variantId,
        'variantId': variantId, // للتوافق
        'id': variantId, // بعض الباك إند القديم قد يطلب id فقط
        
        'quantity': item.quantity,
        'price': price,
      };
    }).toList();
  }

  // ✅ دالة لاستخراج رسالة الخطأ
  Exception _handleError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response?.data;
      final msg = data['message'] ?? data['error'] ?? "حدث خطأ غير معروف";
      return Exception(msg);
    }
    return Exception(e.toString());
  }
}