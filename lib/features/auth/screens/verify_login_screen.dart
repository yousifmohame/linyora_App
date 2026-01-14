import 'dart:async'; // 1. استيراد المؤقت
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
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
  bool _isResending = false; // 2. حالة إعادة الإرسال
  int _countdown = 0; // 3. العداد
  Timer? _timer; // 4. كائن المؤقت

  final Color _brandColor = const Color(0xFFF105C6);

  @override
  void initState() {
    super.initState();
    _startTimer(); // بدء المؤقت عند فتح الصفحة
  }

  @override
  void dispose() {
    _timer?.cancel(); // إيقاف المؤقت عند الخروج
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // 5. دالة بدء العداد
  void _startTimer() {
    setState(() => _countdown = 60); // 60 ثانية
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  // 6. دالة إعادة الإرسال
  Future<void> _handleResendCode() async {
    if (_countdown > 0) return;

    setState(() => _isResending = true);
    try {
      await _authService.resendVerificationCode(widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم إرسال كود جديد ✅"),
            backgroundColor: Colors.green,
          ),
        );
        _startTimer(); // إعادة تشغيل العداد
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handleVerification(String pin) async {
    if (pin.length < 6) return;

    setState(() => _isLoading = true);
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
    // ... (نفس تصميم PinTheme) ...
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
              // ... (نفس الكود السابق للأيقونة والعنوان) ...
              const SizedBox(height: 20),
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

              Pinput(
                length: 6,
                controller: _codeController,
                focusNode: _focusNode,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyDecorationWith(
                  border: Border.all(color: _brandColor, width: 2),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                errorPinTheme: defaultPinTheme.copyDecorationWith(
                  border: Border.all(color: Colors.redAccent),
                  color: Colors.red[50],
                ),
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                showCursor: true,
                onCompleted: (pin) => _handleVerification(pin),
              ),

              const SizedBox(height: 40),

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

              // 7. زر إعادة الإرسال المحدث
            ],
          ),
        ),
      ),
    );
  }
}
