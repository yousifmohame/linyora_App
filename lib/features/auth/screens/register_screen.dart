import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/auth/screens/VerifyRegistrationScreen.dart';
import 'package:linyora_project/features/auth/screens/join_us.dart';
import 'package:linyora_project/features/auth/screens/login_screen.dart';
import 'package:linyora_project/features/auth/screens/verify_login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  final int _customerRoleId = 5;
  // اللون الرئيسي (البنفسجي)
  final Color _primaryColor = const Color(0xFF9333EA);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiClient.post(
        '/auth/register',
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'password': _passwordController.text,
          'roleId': _customerRoleId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم التسجيل بنجاح! يرجى تفعيل حسابك."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          // أو push فقط إذا أردت السماح بالعودة لتصحيح الإيميل
          context,
          MaterialPageRoute(
            builder:
                (_) => VerifyRegistrationScreen(
                  email: _emailController.text.trim(),
                  password:
                      _passwordController.text, // ✅ ضروري جداً للدخول التلقائي
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = "حدث خطأ أثناء التسجيل";
        if (e is DioException && e.response?.data['message'] != null) {
          errorMsg = e.response?.data['message'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء بسيطة

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. العنوان والترحيب
                  const Text(
                    "إنشاء حساب",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "أدخل بياناتك للمتابعة",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 40),

                  // 2. حقول الإدخال (تصميم Minimal)
                  _buildMinimalTextField(
                    controller: _nameController,
                    label: "الاسم الكامل",
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v!.isEmpty ? "الاسم مطلوب" : null,
                  ),
                  const SizedBox(height: 20),
                  _buildMinimalTextField(
                    controller: _emailController,
                    label: "البريد الإلكتروني",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator:
                        (v) => !v!.contains('@') ? "بريد غير صالح" : null,
                  ),
                  const SizedBox(height: 20),
                  _buildMinimalTextField(
                    controller: _phoneController,
                    label: "رقم الهاتف",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildMinimalTextField(
                    controller: _passwordController,
                    label: "كلمة المرور",
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator:
                        (v) => v!.length < 6 ? "كلمة المرور قصيرة" : null,
                  ),

                  const SizedBox(height: 40),

                  // 3. زر التسجيل
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0, // بدون ظل ليكون مسطحاً وبسيطاً
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                "تسجيل حساب جديد",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. الروابط السفلية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "لديك حساب بالفعل؟",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "تسجيل الدخول",
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // رابط الشركاء بتصميم خفيف
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartnerJoinScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text("أنت تاجر أو مورد؟ انضم إلينا هنا"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ودجت الحقول بتصميم بسيط جداً (Minimal)
  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed:
                      () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                )
                : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB), // رمادي فاتح جداً جداً
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        // حدود ناعمة جداً
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // بدون حدود افتراضية ليكون أنظف
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFF3F4F6),
          ), // حدود فاتحة جداً
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }
}
