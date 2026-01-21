import 'dart:io';
import 'dart:ui';
import 'dart:convert'; // لترميز الروابط
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linyora_project/features/models/verification/services/verification_service.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// Providers & Services
import 'package:linyora_project/features/auth/providers/auth_provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final VerificationService _service = VerificationService();
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _followersController = TextEditingController();
  final TextEditingController _accountNumController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();

  // Social Links Controllers
  final Map<String, TextEditingController> _socialControllers = {
    'instagram': TextEditingController(),
    'snapchat': TextEditingController(),
    'tiktok': TextEditingController(),
    'twitter': TextEditingController(),
  };

  // Files
  File? _identityImage;
  File? _ibanCertificate;

  bool _isSubmitting = false;

  // الألوان
  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  @override
  void dispose() {
    _idController.dispose();
    _followersController.dispose();
    _accountNumController.dispose();
    _ibanController.dispose();
    _socialControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- Logic ---

  Future<void> _pickImage(bool isIdentity) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isIdentity) {
          _identityImage = File(image.path);
        } else {
          _ibanCertificate = File(image.path);
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_identityImage == null || _ibanCertificate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى رفع صور الهوية وشهادة الآيبان")),
      );
      return;
    }

    // تجميع الروابط
    Map<String, String> links = {};
    _socialControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) links[key] = controller.text;
    });

    if (links.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إضافة رابط تواصل اجتماعي واحد على الأقل"),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.submitVerification(
        identityNumber: _idController.text,
        identityImage: _identityImage!,
        socialLinks: links,
        followers: _followersController.text,
        accountNumber: _accountNumController.text,
        iban: _ibanController.text,
        ibanCertificate: _ibanCertificate!,
      );

      // تحديث حالة المستخدم محلياً
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم إرسال الطلب بنجاح ✅"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("حدث خطأ: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- Views ---

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final status = user?.verificationStatus ?? 'not_submitted';

    // 1. حالة تم التوثيق (Approved)
    if (status == 'approved') {
      return _buildStatusPage(
        title: "تم توثيق الحساب",
        subtitle: "حسابك نشط الآن ويمكنك البدء في تلقي الطلبات والأرباح.",
        icon: Icons.check_circle,
        gradientColors: [Colors.green, Colors.teal],
        badgeText: "✅ حساب نشط",
        badgeColor: Colors.green.shade100,
        badgeTextColor: Colors.green.shade800,
      );
    }

    // 2. حالة قيد المراجعة (Pending)
    if (status == 'pending') {
      return _buildStatusPage(
        title: "قيد المراجعة",
        subtitle:
            "طلبك قيد المراجعة حالياً من قبل فريقنا. سيتم إشعارك فور الانتهاء.",
        icon: Icons.access_time_filled,
        gradientColors: [Colors.blue, Colors.indigo],
        badgeText: "⏳ قيد الانتظار",
        badgeColor: Colors.amber.shade100,
        badgeTextColor: Colors.amber.shade800,
      );
    }

    // 3. نموذج التقديم (Form)
    return Scaffold(
      extendBodyBehindAppBar: true, // للخلفية
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Stack(
        children: [
          // الخلفية (Gradient & Blobs)
          _buildBackground(),

          // المحتوى
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. المعلومات الشخصية
                            _buildSectionHeader(
                              "المعلومات الشخصية",
                              Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              "رقم الهوية / الإقامة",
                              _idController,
                              isRequired: true,
                            ),
                            const SizedBox(height: 12),
                            _buildUploadField(
                              "صورة الهوية",
                              _identityImage,
                              () => _pickImage(true),
                            ),

                            const Divider(height: 30),

                            // 2. التواصل الاجتماعي
                            _buildSectionHeader(
                              "التواصل الاجتماعي",
                              Icons.public,
                            ),
                            const SizedBox(height: 16),
                            ..._socialControllers.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTextField(
                                  "${entry.key} (الرابط/اليوزر)",
                                  entry.value,
                                  icon: Icons.link,
                                ),
                              ),
                            ),
                            _buildTextField(
                              "عدد المتابعين (تقريباً)",
                              _followersController,
                              isRequired: true,
                              keyboardType: TextInputType.number,
                            ),

                            const Divider(height: 30),

                            // 3. المعلومات البنكية
                            _buildSectionHeader(
                              "المعلومات البنكية",
                              Icons.account_balance,
                            ),
                            const Text(
                              "تستخدم لتحويل الأرباح. تأكدي من دقتها.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              "رقم الحساب",
                              _accountNumController,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              "رقم الآيبان (IBAN)",
                              _ibanController,
                              isRequired: true,
                              hint: "SA...",
                            ),
                            const SizedBox(height: 12),
                            _buildUploadField(
                              "شهادة الآيبان",
                              _ibanCertificate,
                              () => _pickImage(false),
                            ),

                            const SizedBox(height: 30),

                            // زر الإرسال
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitForm,
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
                                    gradient: LinearGradient(
                                      colors: [_roseColor, _purpleColor],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child:
                                        _isSubmitting
                                            ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                            : const Text(
                                              "إرسال الطلب",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Helpers ---

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.pink.shade50.withOpacity(0.4),
                Colors.purple.shade50.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -50,
          right: -50,
          child: _buildBlurBlob(Colors.pink.shade200),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: _buildBlurBlob(Colors.purple.shade200),
        ),
      ],
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildStatusPage({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(icon, size: 50, color: Colors.white),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: badgeTextColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_roseColor, _purpleColor]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _purpleColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_user, size: 40, color: Colors.white),
          SizedBox(height: 10),
          Text(
            "نموذج التوثيق",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "يرجى ملء البيانات التالية بدقة لتوثيق حسابك والبدء.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _purpleColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator:
          isRequired ? (v) => v!.isEmpty ? "هذا الحقل مطلوب" : null : null,
      decoration: InputDecoration(
        labelText: isRequired ? "$label *" : label,
        hintText: hint,
        prefixIcon:
            icon != null ? Icon(icon, color: Colors.grey, size: 18) : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _purpleColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildUploadField(String label, File? file, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label *",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ), // React uses dashed usually, solid is fine here
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.cloud_upload,
                  color: file != null ? Colors.green : _purpleColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file != null
                        ? "تم اختيار الملف: ${file.path.split('/').last}"
                        : "اضغط لرفع الملف (صورة)",
                    style: TextStyle(
                      color: file != null ? Colors.black87 : Colors.grey[600],
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
