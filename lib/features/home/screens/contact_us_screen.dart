import 'package:flutter/material.dart';
import '../services/contact_service.dart'; // تأكد من المسار
// يمكنك استخدام package:url_launcher لفتح الروابط والهاتف

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final ContactService _contactService = ContactService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _contactService.sendMessage(
        name: _nameController.text,
        email: _emailController.text,
        phone: _subjectController.text,
        message: _messageController.text,
      );

      if (!mounted) return;

      // نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("تم إرسال رسالتك بنجاح!"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // تفريغ الحقول
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("فشل الإرسال: حاول مرة أخرى لاحقاً"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // خلفية هادئة
      appBar: AppBar(
        title: const Text(
          "تواصل معنا",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. مقدمة ترحيبية
            const Text(
              "نحن هنا للمساعدة 👋",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "لديك سؤال أو استفسار؟ تواصل معنا عبر النموذج أدناه أو عبر قنوات الاتصال المباشرة.",
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),

            // 2. بطاقات معلومات الاتصال
            Row(
              children: [
                Expanded(
                  child: _ContactInfoCard(
                    icon: Icons.phone_in_talk,
                    title: "خدمة العملاء",
                    content: "+966 50 000 0000",
                    onTap: () {
                      // launchUrl(Uri.parse("tel:+966500000000"));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ContactInfoCard(
                    icon: Icons.email_outlined,
                    title: "البريد الإلكتروني",
                    content: "support@linyora.com",
                    onTap: () {
                      // launchUrl(Uri.parse("mailto:support@linyora.com"));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ContactInfoCard(
              icon: Icons.location_on_outlined,
              title: "المقر الرئيسي",
              content: "الرياض، المملكة العربية السعودية",
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // 3. نموذج المراسلة
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "أرسل لنا رسالة",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameController,
                      label: "الاسم بالكامل",
                      icon: Icons.person_outline,
                      validator: (val) => val!.isEmpty ? "الاسم مطلوب" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: "البريد الإلكتروني",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                          val!.isEmpty || !val.contains('@') ? "بريد غير صالح" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _subjectController,
                      label: "رقم الهاتف",
                      icon: Icons.topic_outlined,
                      validator: (val) => val!.isEmpty ? "رقم الهاتف مطلوب" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _messageController,
                      label: "نص الرسالة",
                      icon: Icons.message_outlined,
                      maxLines: 4,
                      validator: (val) => val!.isEmpty ? "الرسالة مطلوبة" : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // لون احترافي
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "إرسال الرسالة",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 4. تذييل التواصل الاجتماعي
            const Center(
              child: Text("تابعنا على وسائل التواصل", style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(icon: Icons.facebook, color: const Color(0xFF1877F2), onTap: () {}),
                const SizedBox(width: 16),
                _SocialButton(icon: Icons.camera_alt, color: const Color(0xFFE4405F), onTap: () {}), // Instagram style
                const SizedBox(width: 16),
                _SocialButton(icon: Icons.alternate_email, color: const Color(0xFF1DA1F2), onTap: () {}), // Twitter/X style
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ودجت حقل الإدخال
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        alignLabelWithHint: maxLines > 1, // لضبط الأيقونة مع أول سطر في الـ textarea
        filled: true,
        fillColor: Colors.grey[50],
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
          borderSide: const BorderSide(color: Color(0xFFF105C6), width: 1.5),
        ),
      ),
    );
  }
}

// ودجت بطاقة معلومات الاتصال
class _ContactInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final VoidCallback onTap;

  const _ContactInfoCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF105C6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFF105C6), size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              content,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ودجت زر التواصل الاجتماعي
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}