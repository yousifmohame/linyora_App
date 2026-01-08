import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/merchant_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final MerchantService _merchantService = MerchantService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _identityNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ibanController = TextEditingController();

  // Files
  File? _identityImage;
  File? _ibanCertificate;
  File? _businessLicense;

  // State
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _identityNumberController.dispose();
    _businessNameController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(Function(File) onPicked) async {
    // يمكنك إضافة خيار لاختيار PDF هنا باستخدام file_picker إذا أردت مطابقة الويب 100%
    // حالياً نستخدم ImagePicker للتبسيط كما في الكود السابق
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      // التحقق من الحجم (5MB = 5 * 1024 * 1024 bytes)
      final file = File(image.path);
      final size = await file.length();
      if (size > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حجم الملف يجب ألا يتجاوز 5 ميجابايت'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() {
        onPicked(file);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى التأكد من صحة البيانات المدخلة'), backgroundColor: Colors.red),
      );
      return;
    }

    // التحقق من الملفات الإلزامية
    if (_identityImage == null) {
      _showError('صورة الهوية مطلوبة');
      return;
    }
    if (_ibanCertificate == null) {
      _showError('شهادة الآيبان مطلوبة');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      await _merchantService.submitVerification(
        identityNumber: _identityNumberController.text,
        businessName: _businessNameController.text,
        accountNumber: _accountNumberController.text,
        iban: _ibanController.text,
        identityImage: _identityImage!,
        ibanCertificate: _ibanCertificate!,
        businessLicense: _businessLicense,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      if (!mounted) return;
      
      // نجاح العملية
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('تم الإرسال بنجاح')]),
          content: const Text('تم تقديم طلب التوثيق بنجاح وسيتم مراجعته خلال 24-48 ساعة.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back to dashboard
              },
              child: const Text('حسناً'),
            ),
          ],
        ),
      );

    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // خلفية متدرجة (Gradient Background matching web)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Color(0xFFE0E7FF)], // Blue-50 to Indigo-100
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              _buildHeader(),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Steps Indicator
                      _buildStepsIndicator(),
                      
                      const SizedBox(height: 32),
                      
                      // Main Card
                      Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white.withOpacity(0.9),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title Section
                                Row(
                                  children: [
                                    const Icon(Icons.business, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    const Text('نموذج التوثيق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'يرجى ملء جميع الحقول المطلوبة بدقة لتسريع عملية المراجعة',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                                const Divider(height: 32),

                                // Blue Alert Box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'عملية المراجعة تستغرق عادةً من 24 إلى 48 ساعة. سيتم إعلامك عبر البريد الإلكتروني.',
                                          style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // --- Section 1: Personal Info ---
                                _buildSectionTitle(Icons.person, 'المعلومات الشخصية', Colors.blue),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  label: 'رقم الهوية / الإقامة',
                                  controller: _identityNumberController,
                                  hint: 'أدخل رقم الهوية (10 أرقام)',
                                  isRequired: true,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'مطلوب';
                                    if (v.length < 10) return 'يجب أن يكون 10 أرقام على الأقل';
                                    if (!RegExp(r'^\d+$').hasMatch(v)) return 'أرقام فقط';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'اسم المؤسسة (اختياري)',
                                  controller: _businessNameController,
                                  hint: 'اسم المؤسسة أو المنشأة',
                                  helperText: 'اتركه فارغاً إذا كنت تاجر فردي',
                                ),
                                const SizedBox(height: 16),
                                _buildUploadField(
                                  label: 'صورة الهوية / الإقامة',
                                  file: _identityImage,
                                  isRequired: true,
                                  onTap: () => _pickImage((f) => _identityImage = f),
                                ),

                                const SizedBox(height: 32),

                                // --- Section 2: Bank Info ---
                                _buildSectionTitle(Icons.credit_card, 'المعلومات البنكية', Colors.green),
                                const SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'رقم الحساب',
                                        controller: _accountNumberController,
                                        isRequired: true,
                                        keyboardType: TextInputType.number,
                                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'الآيبان (IBAN)',
                                        controller: _ibanController,
                                        isRequired: true,
                                        hint: 'SA...',
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'مطلوب';
                                          if (v.length < 15) return 'قصير جداً';
                                          if (!v.toUpperCase().startsWith('SA')) return 'يجب أن يبدأ بـ SA';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildUploadField(
                                  label: 'شهادة الآيبان',
                                  file: _ibanCertificate,
                                  isRequired: true,
                                  description: 'شهادة الآيبان من البنك (صورة واضحة)',
                                  onTap: () => _pickImage((f) => _ibanCertificate = f),
                                ),
                                const SizedBox(height: 16),
                                _buildUploadField(
                                  label: 'السجل التجاري (اختياري)',
                                  file: _businessLicense,
                                  onTap: () => _pickImage((f) => _businessLicense = f),
                                ),

                                const SizedBox(height: 32),

                                // Upload Progress
                                if (_isSubmitting) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('جاري رفع الملفات...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${(_uploadProgress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(value: _uploadProgress, backgroundColor: Colors.grey[200], color: Colors.purple),
                                  const SizedBox(height: 24),
                                ],

                                // Actions
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('رجوع'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _isSubmitting ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[600],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          elevation: 2,
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text('تقديم للتوثيق', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  SizedBox(width: 8),
                                                  Icon(Icons.arrow_forward, size: 18),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                                
                                // Security Badge Footer
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.security, size: 16, color: Colors.green.shade700),
                                        const SizedBox(width: 8),
                                        Text('جميع بياناتك محمية ومشفرة', style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Center(child: Text('نلتزم بحماية خصوصيتك وأمان بياناتك', style: TextStyle(color: Colors.grey, fontSize: 10))),
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
        ),
      ),
    );
  }

  // --- Helper Widgets to keep code clean ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_user, size: 32, color: Colors.blue.shade700),
          ),
          const SizedBox(height: 16),
          const Text('توثيق الحساب كتاجر', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text('أكمل عملية التوثيق لبدء البيع على منصتنا', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStepsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepItem(1, 'الشخصية', true, Icons.person),
        _buildStepLine(false),
        _buildStepItem(2, 'البنكية', false, Icons.credit_card),
        _buildStepLine(false),
        _buildStepItem(3, 'المستندات', false, Icons.upload_file),
      ],
    );
  }

  Widget _buildStepItem(int num, String title, bool completed, IconData icon) {
    // Note: Logic simplified for display. In real stepper, check currentStep.
    final color = completed ? Colors.green : Colors.white;
    final borderColor = completed ? Colors.green : Colors.grey[300];
    final iconColor = completed ? Colors.white : Colors.grey[400];
    final textColor = completed ? Colors.green[700] : Colors.grey[500];

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor!, width: 2),
          ),
          child: Icon(completed ? Icons.check : icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 20), // Adjust alignment
      color: active ? Colors.green : Colors.grey[300],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool isRequired = false,
    String? helperText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
            children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            helperText: helperText,
            helperStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.purple)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadField({
    required String label,
    required File? file,
    bool isRequired = false,
    String? description,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
            children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: file != null ? Colors.purple : Colors.grey.shade300,
                style: BorderStyle.solid, 
                width: file != null ? 1.5 : 1,
              ),
            ),
            child: file != null 
              ? Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.purple, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(file.path.split('/').last, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.edit, color: Colors.grey, size: 16),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // dashed border imitation logic or simply clean UI
                    Icon(Icons.cloud_upload_outlined, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(isRequired ? 'اختر ملف مطلوب' : 'اختر ملف اختياري', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ],
    );
  }
}