import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

// ✅ استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

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

  Future<void> _saveCard() async {
    final l10n =
        AppLocalizations.of(context)!; // ✅ استدعاء الترجمة لرسائل الخطأ

    if (formKey.currentState!.validate()) {
      if (cardNumber.isEmpty || expiryDate.isEmpty || cvvCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.fillAllFieldsMsg)), // ✅ مترجم
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        if (!expiryDate.contains('/')) {
          throw Exception(l10n.invalidDateFormatMsg); // ✅ مترجم
        }

        final dateParts = expiryDate.split('/');
        final int expMonth = int.parse(dateParts[0]);
        int expYear = int.parse(dateParts[1]);

        if (expYear < 100) {
          expYear += 2000;
        }

        final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');

        await Provider.of<PaymentProvider>(
          context,
          listen: false,
        ).saveCardToStripe(
          cardNumber: cleanCardNumber,
          expMonth: expMonth,
          expYear: expYear,
          cvc: cvvCode,
          holderName: cardHolderName.isEmpty ? 'Unknown' : cardHolderName,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.cardSavedSuccessMsg), // ✅ مترجم
              backgroundColor: Colors.green,
            ),
          );
        }
      } on StripeException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.cardErrorMsg}${e.error.localizedMessage}',
            ), // ✅ مترجم
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.verifyCardDataMsg), // ✅ مترجم
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          l10n.addNewCardTitle, // ✅ مترجم
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                        cardNumberDecoration: _buildInputDecoration(
                          l10n.cardNumberLabel, // ✅ مترجم
                          'XXXX XXXX XXXX XXXX',
                        ),
                        expiryDateDecoration: _buildInputDecoration(
                          l10n.expiryDateLabel, // ✅ مترجم
                          'XX/XX',
                        ),
                        cvvCodeDecoration: _buildInputDecoration(
                          'CVV',
                          'XXX',
                        ), // CVV يبقى كما هو عالمياً
                        cardHolderDecoration: _buildInputDecoration(
                          l10n.cardHolderNameLabel, // ✅ مترجم
                          '',
                        ),
                      ),

                      onCreditCardModelChange: onCreditCardModelChange,
                    ),

                    const SizedBox(height: 20),

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
                                  : Text(
                                    l10n.saveCardBtn, // ✅ مترجم
                                    style: const TextStyle(
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
