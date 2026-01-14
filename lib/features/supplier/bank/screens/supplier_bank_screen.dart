import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/supplier/bank/models/supplier_bank_models.dart';
import 'package:linyora_project/features/supplier/bank/services/supplier_bank_service.dart';

class SupplierBankScreen extends StatefulWidget {
  const SupplierBankScreen({Key? key}) : super(key: key);

  @override
  State<SupplierBankScreen> createState() => _SupplierBankScreenState();
}

class _SupplierBankScreenState extends State<SupplierBankScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupplierBankService _service = SupplierBankService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _bankNameCtrl = TextEditingController();
  final _holderNameCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _accountNumCtrl = TextEditingController();

  // State
  String? _certificateUrl;
  String _status = 'pending';
  String? _rejectionReason;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final details = await _service.getBankDetails();
    if (mounted) {
      setState(() {
        if (details != null) {
          _bankNameCtrl.text = details.bankName;
          _holderNameCtrl.text = details.accountHolderName;
          _ibanCtrl.text = details.iban;
          _accountNumCtrl.text = details.accountNumber ?? '';
          _certificateUrl = details.ibanCertificateUrl;
          _status = details.status;
          _rejectionReason = details.rejectionReason;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await _service.uploadCertificate(File(image.path));
      setState(() => _certificateUrl = url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم رفع الشهادة بنجاح ✅")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("فشل رفع الملف ❌")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_certificateUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى رفع شهادة الآيبان")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final details = SupplierBankDetails(
        bankName: _bankNameCtrl.text,
        accountHolderName: _holderNameCtrl.text,
        iban: _ibanCtrl.text,
        accountNumber: _accountNumCtrl.text,
        ibanCertificateUrl: _certificateUrl,
        status: 'pending', // سيتحول لـ pending عند التعديل
      );

      await _service.saveBankDetails(details);

      if (mounted) {
        setState(() => _status = 'pending'); // تحديث الواجهة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حفظ البيانات بنجاح ✅")),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("فشل الحفظ ❌")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _blurCircle(Colors.blue.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _blurCircle(Colors.purple.withOpacity(0.15)),
          ),

          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildStatusAlert(),
                        const SizedBox(height: 20),

                        // 1. المعلومات الأساسية
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.account_balance,
                                    color: Colors.pink,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "المعلومات الأساسية",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                "اسم البنك",
                                _bankNameCtrl,
                                icon: Icons.museum,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                "اسم صاحب الحساب",
                                _holderNameCtrl,
                                icon: Icons.person,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                "رقم الآيبان (IBAN)",
                                _ibanCtrl,
                                icon: Icons.credit_card,
                                hint: "SA00 0000 ...",
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                "رقم الحساب (اختياري)",
                                _accountNumCtrl,
                                isRequired: false,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. رفع الشهادة
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.description, color: Colors.pink),
                                  SizedBox(width: 8),
                                  Text(
                                    "شهادة الآيبان",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              InkWell(
                                onTap:
                                    _isUploading ? null : _pickAndUploadImage,
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey.shade50,
                                  ),
                                  child:
                                      _isUploading
                                          ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                          : _certificateUrl != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: _buildFilePreview(
                                              _certificateUrl!,
                                            ), // ✅ دالة العرض الذكية
                                          )
                                          : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.cloud_upload_outlined,
                                                size: 40,
                                                color: Colors.pink.shade300,
                                              ),
                                              const SizedBox(height: 10),
                                              const Text(
                                                "اضغط لرفع صورة الشهادة (PDF أو صورة)",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // زر الحفظ
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _submit,
                            icon:
                                _isSaving
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.save),
                            label: const Text(
                              "حفظ البيانات",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF105C6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(String url) {
    bool isPdf = url.toLowerCase().contains('.pdf');

    if (isPdf) {
      return Container(
        color: Colors.red.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text(
              "ملف PDF",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                url.split('/').last, // عرض اسم الملف فقط
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else {
      // إذا كان صورة عادية
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder:
            (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget:
            (context, url, error) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                Text("تعذر تحميل الصورة"),
              ],
            ),
      );
    }
  }

  Widget _buildStatusAlert() {
    Color color;
    IconData icon;
    String title;
    String desc;

    if (_status == 'approved') {
      color = Colors.green;
      icon = Icons.check_circle;
      title = "الحساب موثق";
      desc = "بياناتك البنكية موثقة وجاهزة لاستقبال التحويلات.";
    } else if (_status == 'rejected') {
      color = Colors.red;
      icon = Icons.error;
      title = "تم الرفض";
      desc = "السبب: ${_rejectionReason ?? 'غير محدد'}";
    } else {
      color = Colors.amber;
      icon = Icons.access_time_filled;
      title = "قيد المراجعة";
      desc = "جاري مراجعة بياناتك البنكية من قبل الإدارة.";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    String? hint,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: isRequired ? (v) => v!.isEmpty ? "مطلوب" : null : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _blurCircle(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
