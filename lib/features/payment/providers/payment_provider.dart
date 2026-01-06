import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart'; // مكتبة Stripe
import '../../../models/payment_card_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();
  List<PaymentCardModel> _cards = [];
  bool _isLoading = false;

  List<PaymentCardModel> get cards => _cards;
  bool get isLoading => _isLoading;

  // جلب البطاقات
  Future<void> fetchCards() async {
    _isLoading = true;
    notifyListeners();
    try {
      _cards = await _service.getCards();
    } catch (e) {
      print("Error fetching cards: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // العملية الكاملة لإضافة بطاقة (Setup Intent Flow)
  Future<void> saveCardToStripe({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String holderName,
  }) async {
    try {
      // 1. اطلب من الباك إند إنشاء SetupIntent والحصول على السر
      final clientSecret = await _service.createSetupIntent();

      // 2. تجهيز بيانات البطاقة
      final cardDetails = CardDetails(
        number: cardNumber,
        expirationMonth: expMonth,
        expirationYear: expYear,
        cvc: cvc,
      );

      // 3. (الخطوة المفقودة سابقاً) حقن البيانات في Stripe SDK
      // هذه الدالة تخبر Stripe بأن يستخدم هذه الأرقام في العملية القادمة
      await Stripe.instance.dangerouslyUpdateCardDetails(cardDetails);

      // 4. تأكيد الـ SetupIntent
      // الآن Stripe يعرف الأرقام لأنه تم حقنها في الخطوة السابقة
      await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: clientSecret,
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(name: holderName),
          ),
        ),
      );

      // 5. بعد النجاح، نحدث القائمة
      await fetchCards();
    } catch (e) {
      print("Error in saveCardToStripe: $e");
      rethrow;
    }
  }

  Future<void> deleteCard(String id) async {
    try {
      await _service.deleteCard(id);
      _cards.removeWhere((c) => c.id.toString() == id); // تأكد من نوع الـ ID
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
