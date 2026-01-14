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
      return (response.data as List)
          .map((e) => AddressModel.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching addresses: $e');
      return [];
    }
  }

  // 2. جلب خيارات الشحن لمجموعة منتجات
  // جلب خيارات الشحن لمجموعة منتجات محددة
  Future<List<ShippingOption>> getShippingOptions(List<int> productIds) async {
    try {
      final response = await _apiClient.post(
        '/products/shipping-options-for-cart',
        data: {'productIds': productIds}, // إرسال قائمة الآيديهات فقط
      );

      return (response.data as List)
          .map((e) => ShippingOption.fromJson(e))
          .toList();
    } catch (e) {
      print("Error fetching shipping: $e");
      return [];
    }
  }

  Future<void> placeCardOrder({
    required List<CartItemModel> cartItems,
    required int addressId,
    required List<Map<String, dynamic>> shippingSelections,
    required double shippingCost,
    required double totalAmount,
    required String paymentMethodId,
  }) async {
    try {
      // 1. تجهيز الـ Payload (تم إضافة productId لضمان التوافق)
      final orderPayload = {
        'cartItems':
            cartItems
                .map(
                  (item) => {
                    'id': item.selectedVariant.id,
                    'variant_id': item.selectedVariant.id,
                    'quantity': item.quantity,
                    'price': item.selectedVariant.price,

                    // 🔥 الإصلاح هنا: إرسال المفتاحين لضمان القبول
                    'product_id': item.product.id, // لقاعدة البيانات
                    'productId': item.product.id, // للكود (Node.js Controller)
                  },
                )
                .toList(),
        'shippingAddressId': addressId,
        'shipping_cost': shippingCost,
        'total_amount': totalAmount,
        'merchant_shipping_selections': shippingSelections,
      };

      // 2. إنشاء PaymentIntent
      final intentResponse = await _apiClient.post(
        '/payments/create-intent',
        data: {
          'amount': totalAmount,
          'currency': 'sar',
          'payment_method_id': paymentMethodId,
          'merchant_id':
              cartItems.isNotEmpty ? cartItems.first.product.merchantId : null,
          ...orderPayload,
        },
      );

      final String clientSecret = intentResponse.data['clientSecret'];
      // استخراج ID النية سواء جاء داخل object أو مباشرة
      final String paymentIntentId =
          intentResponse.data['id'] ??
          intentResponse.data['paymentIntentId'] ??
          clientSecret.split('_secret')[0];

      // 3. تأكيد الدفع عبر Stripe SDK
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(
            paymentMethodId: paymentMethodId,
          ),
        ),
      );

      // 4. إنشاء الطلب في الباك إند
      await _apiClient.post(
        '/orders/create-from-intent',
        data: {'paymentIntentId': paymentIntentId, ...orderPayload},
      );
    } on StripeException catch (e) {
      throw Exception(e.error.localizedMessage);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        // محاولة طباعة الخطأ القادم من السيرفر
        throw Exception(
          e.response?.data['message'] ??
              e.response?.data['error'] ??
              "فشلت عملية الدفع",
        );
      }
      throw e;
    }
  }

  // ✅ دالة الدفع عند الاستلام (COD) - تم الإصلاح
  Future<void> placeCodOrder({
    required List<CartItemModel> cartItems,
    required int addressId,
    required List<Map<String, dynamic>> shippingSelections,
    required double shippingCost,
    required double totalAmount,
  }) async {
    // نفس الإصلاح هنا
    final orderPayload = {
      'cartItems':
          cartItems
              .map(
                (item) => {
                  'id': item.selectedVariant.id,
                  'variant_id': item.selectedVariant.id,
                  'quantity': item.quantity,
                  'price': item.selectedVariant.price,

                  // 🔥 الإصلاح: إرسال المفتاحين
                  'product_id': item.product.id,
                  'productId': item.product.id,
                },
              )
              .toList(),
      'shippingAddressId': addressId,
      'shipping_cost': shippingCost,
      'total_amount': totalAmount,
      'merchant_shipping_selections': shippingSelections,
    };

    try {
      await _apiClient.post('/orders/create-cod', data: orderPayload);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? "فشل الطلب");
      }
      throw e;
    }
  }
}
