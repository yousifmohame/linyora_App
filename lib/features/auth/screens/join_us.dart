import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/auth/screens/register_screen.dart'; // للعودة لتسجيل العميل
import 'package:linyora_project/features/auth/screens/verify_login_screen.dart';

class PartnerJoinScreen extends StatefulWidget {
  const PartnerJoinScreen({Key? key}) : super(key: key);

  @override
  State<PartnerJoinScreen> createState() => _PartnerJoinScreenState();
}

class _PartnerJoinScreenState extends State<PartnerJoinScreen> {
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

  // Role Selection
  int? _selectedRoleId;
  final List<Map<String, dynamic>> _roles = [
    {'id': 2, 'label': 'تاجر', 'icon': Icons.store},
    {'id': 6, 'label': 'مورد (دروبشيبينغ)', 'icon': Icons.local_shipping},
    {'id': 3, 'label': 'مودل', 'icon': Icons.camera_alt},
    {'id': 4, 'label': 'مؤثر', 'icon': Icons.star},
  ];

  // دالة التسجيل
  // دالة التسجيل المصححة
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى اختيار نوع الحساب"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiClient.post(
        '/auth/register',
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'password': _passwordController.text,
          'roleId': _selectedRoleId,
        },
      );

      // ✅ الحل: تحقق من أن الشاشة لا تزال موجودة قبل استخدام الـ Context
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم التسجيل بنجاح! يرجى تفعيل حسابك."),
          backgroundColor: Colors.green,
        ),
      );

      // ✅ تحقق مرة أخرى (احتياطاً) قبل الانتقال
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => VerifyLoginScreen(email: _emailController.text.trim()),
        ),
      );
    } catch (e) {
      // ✅ الحل: إذا أغلقت الشاشة وحدث خطأ، لا تحاول عرض السناك بار
      if (!mounted) return;

      String errorMsg = "حدث خطأ أثناء التسجيل";
      if (e is DioException && e.response?.data['message'] != null) {
        errorMsg = e.response?.data['message'];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } finally {
      // ✅ الحل: تأكد من أن الشاشة موجودة قبل تحديث الحالة
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. الخلفية المتدرجة
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF1F2),
                  Color(0xFFFAF5FF),
                  Color(0xFFFFFBEB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. الفقاعات الخلفية
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlurBlob(const Color(0xFFFECDD3).withOpacity(0.3)),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildBlurBlob(const Color(0xFFFDE68A).withOpacity(0.3)),
          ),

          // 3. المحتوى
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                        // الشريط الملون
                        Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFB7185),
                                Color(0xFFA855F7),
                                Color(0xFFFBBF24),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // الأيقونة
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFB7185),
                                        Color(0xFF9333EA),
                                      ],
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
                                    Icons.handshake,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                ShaderMask(
                                  shaderCallback:
                                      (bounds) => const LinearGradient(
                                        colors: [
                                          Color(0xFFE11D48),
                                          Color(0xFF9333EA),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    "انضم كشريك",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "ابدأ رحلة نجاحك معنا كتاجر أو مورد",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // 🔹 قائمة اختيار الدور (Dropdown)
                                DropdownButtonFormField<int>(
                                  value: _selectedRoleId,
                                  items:
                                      _roles
                                          .map(
                                            (role) => DropdownMenuItem<int>(
                                              value: role['id'],
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    role['icon'],
                                                    size: 20,
                                                    color: Colors.grey[700],
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(role['label']),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (val) =>
                                          setState(() => _selectedRoleId = val),
                                  validator:
                                      (val) => val == null ? "مطلوب" : null,
                                  decoration: InputDecoration(
                                    labelText: "نوع الحساب",
                                    prefixIcon: const Icon(
                                      Icons.work_outline,
                                      color: Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF9333EA),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // بقية الحقول
                                _buildTextField(
                                  _nameController,
                                  "الاسم الكامل",
                                  Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  _emailController,
                                  "البريد الإلكتروني",
                                  Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  _phoneController,
                                  "رقم الهاتف",
                                  Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  _passwordController,
                                  "كلمة المرور",
                                  Icons.lock_outline,
                                  isPassword: true,
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
                                          ],
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
                                                  "تسجيل كشريك",
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

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "هل أنت عميل؟ ",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    GestureDetector(
                                      onTap:
                                          () => Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => const RegisterScreen(),
                                            ),
                                          ),
                                      child: const Text(
                                        "سجل هنا",
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      validator: (v) => v!.isEmpty ? "مطلوب" : null,
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
