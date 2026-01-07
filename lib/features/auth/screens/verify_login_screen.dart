import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart'; // تأكد من استيراد المكتبة
import 'package:linyora_project/features/auth/screens/auth_dispatcher.dart';
import '../services/auth_service.dart';

class VerifyLoginScreen extends StatefulWidget {
  final String email;

  const VerifyLoginScreen({super.key, required this.email});

  @override
  State<VerifyLoginScreen> createState() => _VerifyLoginScreenState();
}

class _VerifyLoginScreenState extends State<VerifyLoginScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService.instance;
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  final Color _brandColor = const Color(0xFFF105C6);

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleVerification(String pin) async {
    if (pin.length < 6) return;

    setState(() => _isLoading = true);
    // إخفاء الكيبورد
    FocusScope.of(context).unfocus();

    try {
      final user = await _authService.verifyLogin(widget.email, pin);

      if (mounted && user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AuthDispatcher(user: user)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        // تفريغ الحقل عند الخطأ لإعادة المحاولة
        _codeController.clear();
        _focusNode.requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // إعدادات تصميم مربعات الكود
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 55,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: _brandColor, width: 2),
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.redAccent),
      color: Colors.red[50],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // أيقونة متحركة (اختياري)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _brandColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_rounded,
                  size: 50,
                  color: _brandColor,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "تأكيد الدخول",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "تم إرسال رمز التحقق إلى البريد:\n",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- حقل الكود الاحترافي (Pinput) ---
              Pinput(
                length: 6,
                controller: _codeController,
                focusNode: _focusNode,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                errorPinTheme: errorPinTheme,
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                showCursor: true,
                onCompleted: (pin) => _handleVerification(pin),
              ),

              const SizedBox(height: 40),

              // زر التأكيد
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () => _handleVerification(_codeController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "تأكيد ودخول",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 24),

              // إعادة الإرسال
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "لم يصلك الكود؟ ",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: استدعاء دالة إعادة الإرسال
                    },
                    child: Text(
                      "إعادة إرسال",
                      style: TextStyle(
                        color: _brandColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
