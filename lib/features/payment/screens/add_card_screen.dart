import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({Key? key}) : super(key: key);

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool _isLoading = false;

  void onCreditCardModelChange(CreditCardModel? creditCardModel) {
    setState(() {
      cardNumber = creditCardModel!.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }

  // --- دالة الحفظ الآمن (Stripe Setup Intent) ---
  Future<void> _saveCard() async {
    // 1. طباعة البيانات في الكونسول للتأكد من أنها ليست فارغة
    print("---------------- DEBUG CARD DATA ----------------");
    print("Number: '$cardNumber'");
    print("Date: '$expiryDate'");
    print("CVC: '$cvvCode'");
    print("Holder: '$cardHolderName'");
    print("-------------------------------------------------");

    if (formKey.currentState!.validate()) {
      // تحقق إضافي يدوي لأن validate قد يمرر قيماً فارغة أحياناً
      if (cardNumber.isEmpty || expiryDate.isEmpty || cvvCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تعبئة جميع الحقول')),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        // 2. معالجة التاريخ بدقة
        // التأكد من أن التاريخ يحتوي على /
        if (!expiryDate.contains('/')) {
          throw Exception("تنسيق التاريخ غير صحيح");
        }
        
        final dateParts = expiryDate.split('/');
        final int expMonth = int.parse(dateParts[0]);
        int expYear = int.parse(dateParts[1]);
        
        // تحويل السنة من رقمين (25) إلى 4 أرقام (2025) إذا لزم الأمر
        if (expYear < 100) {
          expYear += 2000;
        }

        // 3. تنظيف رقم البطاقة من المسافات (أهم خطوة)
        final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');

        // 4. استدعاء البروفايدر
        await Provider.of<PaymentProvider>(context, listen: false).saveCardToStripe(
          cardNumber: cleanCardNumber, // الرقم المنظف
          expMonth: expMonth,
          expYear: expYear,
          cvc: cvvCode,
          holderName: cardHolderName.isEmpty ? 'Unknown' : cardHolderName,
        );

        if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ البطاقة بنجاح ✅'),
              backgroundColor: Colors.green,
            ),
          );
        }

      } on StripeException catch (e) {
        print("Stripe Error: ${e.error.localizedMessage}"); // طباعة خطأ سترايب
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في البطاقة: ${e.error.localizedMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        print("General Error: $e"); // طباعة الخطأ العام
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تأكد من صحة بيانات البطاقة'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      print("Form validation failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "إضافة بطاقة جديدة",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. شكل البطاقة
            CreditCardWidget(
              cardNumber: cardNumber,
              expiryDate: expiryDate,
              cardHolderName: cardHolderName,
              cvvCode: cvvCode,
              showBackView: isCvvFocused,
              obscureCardNumber: true,
              obscureCardCvv: true,
              isHolderNameVisible: true,
              cardBgColor: const Color(0xFF1E1E1E),
              isSwipeGestureEnabled: true,
              onCreditCardWidgetChange: (CreditCardBrand creditCardBrand) {},
              customCardTypeIcons: const <CustomCardTypeIcon>[],
            ),

            // 2. نموذج الإدخال
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CreditCardForm(
                      formKey: formKey,
                      obscureCvv: true,
                      obscureNumber: true,
                      cardNumber: cardNumber,
                      cvvCode: cvvCode,
                      isHolderNameVisible: true,
                      isCardNumberVisible: true,
                      isExpiryDateVisible: true,
                      cardHolderName: cardHolderName,
                      expiryDate: expiryDate,

                      inputConfiguration: InputConfiguration(
                        // ✅ التعديل الثاني: حذف labelStyle و inputStyle من هنا
                        cardNumberDecoration: _buildInputDecoration(
                          'رقم البطاقة',
                          'XXXX XXXX XXXX XXXX',
                        ),
                        expiryDateDecoration: _buildInputDecoration(
                          'تاريخ الانتهاء',
                          'XX/XX',
                        ),
                        cvvCodeDecoration: _buildInputDecoration('CVV', 'XXX'),
                        cardHolderDecoration: _buildInputDecoration(
                          'اسم حامل البطاقة',
                          '',
                        ),
                      ),

                      onCreditCardModelChange: onCreditCardModelChange,
                    ),

                    const SizedBox(height: 20),

                    // 3. زر الحفظ
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveCard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF105C6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'حفظ البطاقة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      // ✅ التعديل الثالث: تحديد لون العنوان (Label) هنا
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      hintStyle: const TextStyle(color: Colors.grey),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF105C6), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
