import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class PaymentService {
  final ApiClient _apiClient =
      ApiClient(); // ✅ هذا هو البطل، سيجلب التوكن تلقائياً

  // في ملف payment_service.dart

  Future<void> subscribeToPlan({
    required BuildContext context,
    required int planId,
    String? paymentMethodId,
    required Function onSuccess,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final response = await _apiClient.post(
        '/payments/mobile/create-subscription',
        data: {'planId': planId, 'paymentMethodId': paymentMethodId},
      );

      Navigator.pop(context);

      final responseData = response.data;
      final String? clientSecret = responseData['clientSecret'];
      final String status = responseData['status'];
      // ✅ نستلم ID البطاقة من الباك إند
      final String? usedPaymentMethodId = responseData['paymentMethodId'];

      if (status == 'incomplete') {
        if (clientSecret != null && usedPaymentMethodId != null) {
          // ✅ الحل: نستخدم cardFromMethodId بدلاً من card
          await Stripe.instance.confirmPayment(
            paymentIntentClientSecret: clientSecret,
            data: PaymentMethodParams.cardFromMethodId(
              paymentMethodData: PaymentMethodDataCardFromMethod(
                paymentMethodId: usedPaymentMethodId, // نمرر الـ ID هنا
              ),
            ),
          );

          onSuccess();
        } else {
          throw "بيانات الدفع غير مكتملة";
        }
      } else if (status == 'active') {
        onSuccess();
      } else {
        throw "حالة غير معروفة: $status";
      }
    } catch (e) {
      Navigator.of(context).maybePop();
      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الدفع: ${e.error.localizedMessage}')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الاشتراك: $e')));
      }
    }
  }

  Future<void> promoteProduct({
    required BuildContext context,
    required int productId,
    required int tierId,
    required Function onSuccess,
  }) async {
    try {
      // 1. طلب PaymentIntent من الباك إند
      // ملاحظة: تأكد من وجود هذا المسار في الباك إند أو أنشئه (سأضع لك كوده في الأسفل للاحتياط)
      final response = await _apiClient.post(
        '/payments/mobile/create-promotion-intent',
        data: {'product_id': productId, 'tier_id': tierId},
      );

      final String clientSecret = response.data['clientSecret'];
      final String customerId =
          response.data['customer']; // اختياري حسب الباك إند

      // 2. تهيئة نافذة الدفع
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Linyora',
          customerId: customerId,
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: Color(0xFFF105C6)),
          ),
        ),
      );

      // 3. عرض النافذة
      await Stripe.instance.presentPaymentSheet();

      // 4. نجاح
      onSuccess();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إلغاء العملية')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.error.localizedMessage}')),
        );
      }
    } on DioException catch (e) {
      String msg = e.response?.data['message'] ?? 'فشل الاتصال بالسيرفر';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      print("Promotion Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ غير متوقع')));
    }
  }

  Future<void> payForAgreement({
    required BuildContext context,
    required int modelId,
    required int productId,
    int? packageTierId,
    int? offerId,
    required Function onSuccess,
  }) async {
    try {
      // ✅ التعديل الجذري: نستخدم مسار واحد موحد لكل الحالات
      // هذا المسار (create-agreement-intent) هو الذي يحتوي على logic الـ metadata الصحيح في الباك إند
      const String endpoint = '/payments/mobile/create-agreement-intent';

      final response = await _apiClient.post(
        endpoint,
        data: {
          'model_id': modelId,
          'product_id': productId,
          // نرسل القيم، والباك إند سيتعامل مع الـ null
          'package_tier_id': packageTierId,
          'offer_id': offerId,
        },
      );

      final String clientSecret = response.data['clientSecret'];
      final String? customerId =
          response.data['customer']; // قد يكون null وهذا طبيعي

      // 2. تهيئة نافذة الدفع
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Linyora Agreements',
          customerId: customerId,
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: Color(0xFFF43F5E)),
          ),
        ),
      );

      // 3. عرض النافذة
      await Stripe.instance.presentPaymentSheet();

      // 4. نجاح
      onSuccess();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إلغاء العملية')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.error.localizedMessage}')),
        );
      }
    } catch (e) {
      print("Agreement Payment Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء معالجة الطلب')),
      );
    }
  }
}
