import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService.instance;
  
  bool _isLoading = false;
  final Color _brandColor = const Color(0xFFF105C6);

  Future<void> _handleReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // استدعاء دالة الاستعادة
      await _authService.forgotPassword(_emailController.text.trim());

      if (mounted) {
        // إظهار رسالة نجاح أو الانتقال لشاشة إدخال الكود
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                const SizedBox(height: 20),
                const Text(
                  "تم الإرسال!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "راجع بريدك الإلكتروني، لقد أرسلنا رابطاً لاستعادة كلمة المرور.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // إغلاق الشيت
                      Navigator.pop(context); // العودة للدخول
                    },
                    style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.black,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.all(16)
                    ),
                    child: const Text("حسناً"),
                  ),
                )
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _brandColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_reset, size: 40, color: _brandColor),
                ),
                const SizedBox(height: 30),
                const Text(
                  "نسيت كلمة المرور؟ 🔒",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  "لا تقلق! أدخل بريدك الإلكتروني وسنرسل لك تعليمات الاستعادة.",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _brandColor, width: 1.5),
                    ),
                  ),
                  validator: (v) => !v!.contains('@') ? 'بريد غير صالح' : null,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "إرسال الرابط",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}