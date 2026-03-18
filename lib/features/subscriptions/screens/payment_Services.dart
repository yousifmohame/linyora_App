import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';

// ✅ استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../../../../core/api/api_client.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  Future<void> subscribeToPlan({
    required BuildContext context,
    required int planId,
    String? paymentMethodId,
    required Function onSuccess,
    required AppLocalizations l10n,
  }) async {
    try {
      // إظهار مؤشر التحميل أثناء الاتصال بالباك إند
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final response = await _apiClient.post(
        '/payments/mobile/create-subscription',
        data: {'planId': planId, 'paymentMethodId': paymentMethodId},
      );

      // إغلاق مؤشر التحميل
      if (context.mounted) Navigator.pop(context);

      final responseData = response.data;
      final String? clientSecret = responseData['clientSecret'];
      final String status = responseData['status'];
      final String? usedPaymentMethodId = responseData['paymentMethodId'];
      final String? customerId =
          responseData['customer']; // ✅ جلب كود العميل إن وُجد

      // معالجة الحالات التي تتطلب تدخلاً (الدفع غير مكتمل أو يتطلب إدخال بطاقة)
      if (status == 'incomplete' ||
          status == 'requires_payment_method' ||
          status == 'requires_action') {
        if (clientSecret != null) {
          if (usedPaymentMethodId != null) {
            // ✅ الحالة الأولى: العميل لديه بطاقة مسجلة (تأكيد الدفع الصامت أو 3D Secure)
            await Stripe.instance.confirmPayment(
              paymentIntentClientSecret: clientSecret,
              data: PaymentMethodParams.cardFromMethodId(
                paymentMethodData: PaymentMethodDataCardFromMethod(
                  paymentMethodId: usedPaymentMethodId,
                ),
              ),
            );
            onSuccess();
          } else {
            // ✅ الحالة الثانية: العميل ليس لديه بطاقة! (نفتح شاشة الدفع Payment Sheet)
            await Stripe.instance.initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                paymentIntentClientSecret: clientSecret,
                merchantDisplayName: 'Linyora',
                customerId: customerId,
                style: ThemeMode.light,
                appearance: const PaymentSheetAppearance(
                  // لون أخضر ليتناسب مع تصميم الاشتراكات
                  colors: PaymentSheetAppearanceColors(
                    primary: Color(0xFF10B981),
                  ),
                ),
              ),
            );

            await Stripe.instance.presentPaymentSheet();
            onSuccess();
          }
        } else {
          throw l10n.incompletePaymentDataMsg;
        }
      } else if (status == 'active') {
        // الدفع تم بنجاح بدون حاجة لتدخل إضافي
        onSuccess();
      } else {
        throw "${l10n.unknownStateMsg}$status";
      }
    } on StripeException catch (e) {
      if (context.mounted)
        Navigator.of(context).maybePop(); // إغلاق أي نافذة تحميل عالقة

      // ✅ التأكد من عدم إظهار خطأ أحمر إذا قام المستخدم فقط بإغلاق شاشة الدفع بيده
      if (e.error.code == FailureCode.Canceled) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.operationCancelledMsg)));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.paymentFailedMsg}${e.error.localizedMessage}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).maybePop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.subscriptionFailedMsg}$e')),
        );
      }
    }
  }

  // ... (باقي الدوال promoteProduct و payForAgreement تظل كما هي بدون تغيير)

  Future<void> promoteProduct({
    required BuildContext context,
    required int productId,
    required int tierId,
    required Function onSuccess,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await _apiClient.post(
        '/payments/mobile/create-promotion-intent',
        data: {'product_id': productId, 'tier_id': tierId},
      );

      final String clientSecret = response.data['clientSecret'];
      final String customerId = response.data['customer'];

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

      await Stripe.instance.presentPaymentSheet();
      onSuccess();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.operationCancelledMsg)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorPrefix}${e.error.localizedMessage}'),
          ),
        );
      }
    } on DioException catch (e) {
      String msg =
          e.response?.data['message'] ?? l10n.serverConnectionFailedMsg;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.unexpectedErrorMsg)));
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
    final l10n = AppLocalizations.of(context)!;
    try {
      const String endpoint = '/payments/mobile/create-agreement-intent';

      final response = await _apiClient.post(
        endpoint,
        data: {
          'model_id': modelId,
          'product_id': productId,
          'package_tier_id': packageTierId,
          'offer_id': offerId,
        },
      );

      final String clientSecret = response.data['clientSecret'];
      final String? customerId = response.data['customer'];

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

      await Stripe.instance.presentPaymentSheet();
      onSuccess();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.operationCancelledMsg)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorPrefix}${e.error.localizedMessage}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorProcessingRequestMsg)));
    }
  }
}
