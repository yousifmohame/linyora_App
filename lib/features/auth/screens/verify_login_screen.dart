import 'package:flutter/material.dart';
import 'package:linyora_project/features/auth/screens/auth_dispatcher.dart';
import '../services/auth_service.dart';

class VerifyLoginScreen extends StatefulWidget {
  final String email; // نستقبل الإيميل من الصفحة السابقة

  const VerifyLoginScreen({super.key, required this.email});

  @override
  State<VerifyLoginScreen> createState() => _VerifyLoginScreenState();
}

class _VerifyLoginScreenState extends State<VerifyLoginScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleVerification() async {
    if (_codeController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الكود المكون من 6 أرقام')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.verifyLogin(
        widget.email,
        _codeController.text.trim(),
      );

      if (mounted && user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            // نمرر المستخدم للموجه ليختار الشاشة المناسبة
            builder: (context) => AuthDispatcher(user: user),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تأكيد الدخول")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.mark_email_read_outlined, size: 60),
            const SizedBox(height: 20),
            Text(
              "تم إرسال رمز التحقق إلى\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: "000000",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("تأكيد ودخول"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}