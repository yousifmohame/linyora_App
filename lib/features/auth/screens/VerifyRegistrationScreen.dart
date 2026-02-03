import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../services/auth_service.dart';
import 'verify_login_screen.dart'; // سنحتاجها للانتقال إليها

class VerifyRegistrationScreen extends StatefulWidget {
  final String email;
  final String password; // نحتاجها لطلب الدخول التلقائي بعد التفعيل

  const VerifyRegistrationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<VerifyRegistrationScreen> createState() =>
      _VerifyRegistrationScreenState();
}

class _VerifyRegistrationScreenState extends State<VerifyRegistrationScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService.instance;

  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 0;
  Timer? _timer;

  final Color _brandColor = const Color(
    0xFFE11D48,
  ); // لون مختلف قليلاً لتمييز الشاشة (اختياري)

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0)
        timer.cancel();
      else
        setState(() => _countdown--);
    });
  }

  Future<void> _handleActivation(String pin) async {
    if (pin.length < 6) return;
    setState(() => _isLoading = true);

    try {
      // 1. تفعيل الحساب
      bool activated = await _authService.verifyAccount(widget.email, pin);

      if (activated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم تفعيل الحساب بنجاح! 🚀 جاري تسجيل الدخول..."),
            backgroundColor: Colors.green,
          ),
        );

        // 2. طلب تسجيل الدخول تلقائياً (لإرسال كود الدخول)
        await _authService.login(widget.email, widget.password);

        if (mounted) {
          // 3. التوجيه لشاشة التحقق من الدخول
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyLoginScreen(email: widget.email),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        _codeController.clear();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_countdown > 0) return;
    setState(() => _isResending = true);
    try {
      // هنا نستخدم دالة إعادة إرسال كود التفعيل وليس الدخول
      // ملاحظة: تأكد من الباك إند هل يستخدم نفس endpoint أو مختلف
      // عادة resendVerification تعمل للاثنين
      await _authService.resendVerificationCode(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم إرسال كود التفعيل")));
        _startTimer();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (نفس تصميم UI السابق ولكن مع نصوص "تفعيل الحساب")
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 55,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.verified_user_outlined,
                size: 60,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              const Text(
                "تفعيل الحساب الجديد",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "تم إرسال رمز التفعيل إلى ${widget.email}",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              Pinput(
                length: 6,
                controller: _codeController,
                defaultPinTheme: defaultPinTheme,
                onCompleted: _handleActivation,
                focusedPinTheme: defaultPinTheme.copyDecorationWith(
                  border: Border.all(color: Colors.green),
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () => _handleActivation(_codeController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "تفعيل الحساب",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: (_countdown > 0) ? null : _handleResend,
                child: Text(
                  _countdown > 0
                      ? "إعادة الإرسال $_countdown"
                      : "إعادة إرسال الرمز",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
