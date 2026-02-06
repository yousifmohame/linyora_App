import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../models/cart_item_model.dart';

class CartService {
  final ApiClient _apiClient = ApiClient();

  // إرسال الطلب للسيرفر
  // ✅ التعديل: نمرر العنوان وطريقة الدفع كمعاملات (Parameters)
  Future<void> placeOrder({
    required List<CartItemModel> items,
    required int addressId,
    String paymentMethod = 'cod', // قيمة افتراضية
  }) async {
    try {
      // تجهيز البيانات
      final List<Map<String, dynamic>> orderItems = items.map((item) {
        // ✅ 1. تحديد السعر الصحيح (سعر المتغير أو سعر المنتج الأصلي)
        final double finalPrice = item.selectedVariant?.price ?? item.product.price;

        return {
          'product_id': item.product.id,
          
          // ✅ 2. معالجة الـ Null Safety للمتغير
          // إذا كان selectedVariant يساوي null، سيرسل null، وإلا سيرسل الـ id
          'variant_id': item.selectedVariant?.id, 
          
          'quantity': item.quantity,
          'price': finalPrice, // يفضل إرسال السعر للتحقق في الباك إند
        };
      }).toList();

      // إرسال الطلب
      await _apiClient.post('/orders', data: {
        'items': orderItems,
        'payment_method': paymentMethod, 
        'shipping_address_id': addressId, // ✅ استخدام القيمة الممررة
        // يمكن إضافة total_amount هنا إذا كان الباك إند يطلبه
      });
      
    } catch (e) {
      // ✅ 3. تحسين قراءة الأخطاء من Dio
      if (e is DioException && e.response?.data != null) {
        final errorMsg = e.response?.data['message'] ?? e.response?.data['error'] ?? 'حدث خطأ غير معروف';
        throw Exception(errorMsg);
      }
      
      print('Checkout Error: $e');
      throw Exception('فشل إتمام الطلب، يرجى المحاولة لاحقاً');
    }
  }
}