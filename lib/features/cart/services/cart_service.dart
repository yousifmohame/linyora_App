import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../models/cart_item_model.dart';

class CartService {
  final ApiClient _apiClient = ApiClient();

  // إرسال الطلب للسيرفر
  Future<void> placeOrder(List<CartItemModel> items) async {
    try {
      // تجهيز البيانات بالشكل الذي يطلبه الباك اند (orderRoutes/orderController)
      // عادة يتوقع الباك اند قائمة بـ {variant_id, quantity}
      final List<Map<String, dynamic>> orderItems = items.map((item) {
        return {
          'variant_id': item.selectedVariant.id,
          'quantity': item.quantity,
          // قد تحتاج لإرسال product_id أيضاً حسب تصميم الباك اند
          'product_id': item.product.id, 
        };
      }).toList();

      // إرسال الطلب
      // تأكد من المسار الصحيح في الباك اند (مثلاً /orders)
      await _apiClient.post('/orders', data: {
        'items': orderItems,
        'payment_method': 'cod', // افتراضياً الدفع عند الاستلام، يمكن تغييره
        'shipping_address_id': 1, // يجب تمرير عنوان حقيقي هنا لاحقاً
      });
      
    } catch (e) {
      print('Checkout Error: $e');
      throw Exception('فشل إتمام الطلب، يرجى المحاولة لاحقاً');
    }
  }

  // يمكن إضافة دوال أخرى هنا مثل:
  // - التحقق من توفر الكميات (Validate Stock)
  // - حساب تكلفة الشحن (Calculate Shipping)
}