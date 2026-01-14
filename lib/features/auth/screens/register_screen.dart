import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart'; // تأكد من مسار الـ ApiClient
import 'package:linyora_project/features/auth/screens/join_us.dart';
import 'package:linyora_project/features/auth/screens/login_screen.dart';
import 'package:linyora_project/features/auth/screens/verify_login_screen.dart'; // افترض وجود شاشة تسجيل الدخول

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

  // الثوابت
  final int _customerRoleId = 5;

  // دالة التسجيل
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // إرسال البيانات للباك إند
      await _apiClient.post(
        '/auth/register',
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'password': _passwordController.text,
          'roleId': _customerRoleId, // تثبيت الدور كعميل
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم التسجيل بنجاح! يرجى تفعيل حسابك."),
            backgroundColor: Colors.green,
          ),
        );

        // الانتقال لصفحة التحقق من الإيميل
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => VerifyLoginScreen(email: _emailController.text.trim()),
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
      String msg = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. الخلفية المتدرجة (Background Gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF1F2),
                  Color(0xFFFAF5FF),
                  Color(0xFFFFFBEB),
                ], // Rose-50, Purple-50, Amber-50
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. الدوائر الضبابية الخلفية (Background Blobs)
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlurBlob(
              const Color(0xFFFECDD3).withOpacity(0.3),
            ), // Rose-200
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildBlurBlob(
              const Color(0xFFFDE68A).withOpacity(0.3),
            ), // Amber-200
          ),

          // 3. المحتوى (Card)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10,
                    sigmaY: 10,
                  ), // تأثير الزجاج
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الشريط الملون العلوي
                        Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFB7185),
                                Color(0xFFA855F7),
                                Color(0xFFFBBF24),
                              ], // Rose-400 to Amber-400
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // أيقونة التاج
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFB7185),
                                        Color(0xFF9333EA),
                                      ], // Rose to Purple
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF9333EA,
                                        ).withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium,
                                    color: Colors.white,
                                    size: 40,
                                  ), // Crown Icon
                                ),

                                const SizedBox(height: 24),

                                // العنوان (Gradient Text)
                                ShaderMask(
                                  shaderCallback:
                                      (bounds) => const LinearGradient(
                                        colors: [
                                          Color(0xFFE11D48),
                                          Color(0xFF9333EA),
                                        ], // Rose-600 to Purple-600
                                      ).createShader(bounds),
                                  child: const Text(
                                    "إنشاء حساب عميل",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "انضم إلينا وابدأ رحلة تسوق مميزة",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // حقول الإدخال
                                _buildTextField(
                                  controller: _nameController,
                                  hint: "الاسم الكامل",
                                  icon: Icons.person_outline,
                                  validator:
                                      (v) => v!.isEmpty ? "الاسم مطلوب" : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _emailController,
                                  hint: "البريد الإلكتروني",
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator:
                                      (v) =>
                                          !v!.contains('@')
                                              ? "بريد غير صالح"
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _phoneController,
                                  hint: "رقم الهاتف",
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _passwordController,
                                  hint: "كلمة المرور",
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  validator:
                                      (v) =>
                                          v!.length < 6
                                              ? "كلمة المرور قصيرة"
                                              : null,
                                ),

                                const SizedBox(height: 32),

                                // زر التسجيل
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFE11D48),
                                            Color(0xFF9333EA),
                                          ], // Rose to Purple
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        child:
                                            _isLoading
                                                ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                                : const Text(
                                                  "تسجيل حساب جديد",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // روابط سفلية
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "هل أنت شريك؟ ",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PartnerJoinScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "انضم كتاجر أو مورد",
                                        style: TextStyle(
                                          color: Color(0xFF9333EA),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "لديك حساب بالفعل؟ ",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    GestureDetector(
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => const LoginScreen(),
                                            ),
                                          ),
                                      child: const Text(
                                        "تسجيل الدخول",
                                        style: TextStyle(
                                          color: Color(0xFF9333EA),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت للحقول (TextField)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
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
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed:
                      () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                )
                : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9333EA)),
        ),
      ),
    );
  }

  // ودجت للدوائر الخلفية
  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
