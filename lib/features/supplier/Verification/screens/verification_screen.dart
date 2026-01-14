import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:linyora_project/features/dashboards/supplier_dashboard.dart';
import 'package:linyora_project/features/supplier/Verification/services/supplier_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupplierService _service = SupplierService();

  // Controllers
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _accountNumController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();

  // Files
  File? _identityImage;
  File? _businessLicense;
  File? _ibanCertificate;

  // State
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  // دالة اختيار الملفات
  Future<void> _pickFile(Function(File) onFilePicked) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        onFilePicked(File(result.files.single.path!));
      });
    }
  }

  // دالة الإرسال
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // التحقق من الملفات الإجبارية يدوياً
    if (_identityImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ صورة الهوية مطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_ibanCertificate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ شهادة الآيبان مطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      await _service.submitVerification(
        identityNumber: _idController.text,
        businessName: _businessNameController.text,
        accountNumber: _accountNumController.text,
        iban: _ibanController.text,
        identityImage: _identityImage!,
        businessLicense: _businessLicense,
        ibanCertificate: _ibanCertificate!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال الطلب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SupplierDashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل الإرسال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // خلفية رمادية فاتحة
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. بطاقة العنوان (Header Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      size: 50,
                      color: Color(0xFF9333EA),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "توثيق حساب المورد",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "يرجى تقديم المعلومات والمستندات التالية لبدء العمل كمورد دروبشيبينغ.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. معلومات الهوية والعمل
              _buildSectionTitle(Icons.person, "معلومات الهوية والعمل"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _idController,
                      label: "رقم الهوية / الإقامة *",
                      validator:
                          (v) =>
                              v!.length < 10
                                  ? "يجب أن يكون 10 أرقام على الأقل"
                                  : null,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _businessNameController,
                      label: "اسم المؤسسة (اختياري)",
                    ),
                    const SizedBox(height: 16),
                    _buildFileUpload(
                      label: "صورة الهوية / الإقامة *",
                      file: _identityImage,
                      onTap: () => _pickFile((f) => _identityImage = f),
                    ),
                    const SizedBox(height: 16),
                    _buildFileUpload(
                      label: "السجل التجاري (اختياري)",
                      file: _businessLicense,
                      onTap: () => _pickFile((f) => _businessLicense = f),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. المعلومات البنكية
              _buildSectionTitle(Icons.credit_card, "المعلومات البنكية"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _accountNumController,
                      label: "رقم الحساب البنكي *",
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "هذا الحقل مطلوب" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _ibanController,
                      label: "رقم الآيبان (IBAN) *",
                      validator:
                          (v) => v!.length < 15 ? "تأكد من صحة الآيبان" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildFileUpload(
                      label: "شهادة الآيبان *",
                      file: _ibanCertificate,
                      onTap: () => _pickFile((f) => _ibanCertificate = f),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. ملاحظة وتنبيه
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ملاحظة هامة",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "سيتم مراجعة طلبك خلال 24-48 ساعة عمل.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. شريط التقدم وزر الإرسال
              if (_isSubmitting) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  color: const Color(0xFFF105C6),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 8),
                Text(
                  "جاري رفع المستندات... ${(_uploadProgress * 100).toInt()}%",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF105C6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "إرسال طلب التوثيق",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets مساعدة ---

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[800]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildFileUpload({
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ), // Dash effect needs external package, solid is fine
            ),
            child: Row(
              children: [
                Icon(
                  file == null
                      ? Icons.cloud_upload_outlined
                      : Icons.check_circle,
                  color: file == null ? Colors.grey : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file == null
                        ? "انقر لرفع الملف"
                        : file.path.split('/').last,
                    style: TextStyle(
                      color: file == null ? Colors.grey : Colors.black87,
                    ),
                    maxLines: 1,
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
