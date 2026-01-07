import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'verify_login_screen.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService.instance;
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // الثابت الخاص بالعميل كما في كود React
  static const int CUSTOMER_ROLE_ID = 5;
  
  // ألوان التصميم المستوحاة من الكود
  final Color _brandColor = const Color(0xFFF105C6); // اللون الوردي الأساسي
  final Color _purpleColor = const Color(0xFF9333EA);

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        roleId: CUSTOMER_ROLE_ID, // 👈 نرسل رقم 5 مباشرة
      );

      if (!mounted) return;

      if (success) {
        // الانتقال لصفحة التحقق
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyLoginScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // خلفية متدرجة تشبه كود الويب
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF1F2), // Rose-50
              Color(0xFFFAF5FF), // Purple-50
              Color(0xFFFFFBEB), // Amber-50
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 10,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: Colors.white.withOpacity(0.9), // شفافية بسيطة
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- الهيدر (أيقونة التاج) ---
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.pink[300]!, Colors.purple[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            // أيقونة التاج (Crown)
                            child: const Icon(Icons.emoji_events, size: 40, color: Colors.white), 
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // --- العناوين ---
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.pink[600]!, Colors.purple[600]!],
                          ).createShader(bounds),
                          child: const Text(
                            "إنشاء حساب عميل",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // اللون يأتي من الـ Shader
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "استمتع بتجربة تسوق فريدة مع Linyora",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 30),

                        // --- الحقول ---
                        _buildTextField(
                          controller: _nameController,
                          label: 'الاسم الكامل',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _emailController,
                          label: 'البريد الإلكتروني',
                          icon: Icons.email_outlined,
                          inputType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _phoneController,
                          label: 'رقم الهاتف',
                          icon: Icons.phone_iphone,
                          inputType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _inputDecoration(
                            label: 'كلمة المرور',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (v) => v!.length < 6 ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : null,
                        ),

                        const SizedBox(height: 30),

                        // --- زر التسجيل ---
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, // لعمل تدرج لوني
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_brandColor, _purpleColor],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        "تسجيل جديد",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- الروابط السفلية ---
                        Column(
                          children: [
                            // رابط الشركاء
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("هل أنت شريك؟ ", style: TextStyle(color: Colors.grey[600])),
                                GestureDetector(
                                  onTap: () {
                                    // الانتقال لصفحة Join Us (التاجر/المودل)
                                    // Navigator.pushReplacement(
                                    //   context,
                                    //   MaterialPageRoute(builder: (context) => const JoinUsScreen()),
                                    // );
                                  },
                                  child: Text(
                                    "انضم إلينا هنا",
                                    style: TextStyle(
                                      color: _purpleColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // رابط تسجيل الدخول
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("لديك حساب بالفعل؟ ", style: TextStyle(color: Colors.grey[600])),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context); // العودة لشاشة الدخول
                                  },
                                  child: Text(
                                    "تسجيل الدخول",
                                    style: TextStyle(
                                      color: _purpleColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- دوال التصميم المساعدة ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: _inputDecoration(label: label, icon: icon),
      validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[50], // لون خلفية الحقل فاتح جداً
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _brandColor),
      ),
    );
  }
}