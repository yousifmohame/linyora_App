import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/bank_details_model.dart';
import '../services/bank_service.dart';

class BankSettingsScreen extends StatefulWidget {
  const BankSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BankSettingsScreen> createState() => _BankSettingsScreenState();
}

class _BankSettingsScreenState extends State<BankSettingsScreen> {
  final BankService _service = BankService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _holderNameCtrl = TextEditingController();
  final TextEditingController _ibanCtrl = TextEditingController();
  final TextEditingController _accountNumberCtrl = TextEditingController();

  BankDetails _details = BankDetails();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  // Colors (Rose Theme)
  final Color rose50 = const Color(0xFFFFF1F2);
  final Color rose100 = const Color(0xFFFFE4E6);
  final Color rose500 = const Color(0xFFF43F5E);
  final Color rose600 = const Color(0xFFE11D48);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _service.getBankDetails();
      setState(() {
        _details = data;
        _bankNameCtrl.text = data.bankName;
        _holderNameCtrl.text = data.accountHolderName;
        _ibanCtrl.text = data.iban;
        _accountNumberCtrl.text = data.accountNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _isUploading = true);
      try {
        final url = await _service.uploadCertificate(File(picked.path));
        if (url != null) {
          setState(() {
            _details.ibanCertificateUrl = url;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفع الشهادة بنجاح'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل رفع الملف'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // تحديث المودل بالقيم من الكنترولرز
    _details.bankName = _bankNameCtrl.text;
    _details.accountHolderName = _holderNameCtrl.text;
    _details.iban = _ibanCtrl.text;
    _details.accountNumber = _accountNumberCtrl.text;

    setState(() => _isSaving = true);
    try {
      await _service.updateBankDetails(_details);
      await _fetchData(); // تحديث الحالة
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ البيانات وإرسالها للمراجعة'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء الحفظ'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [rose50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: rose500))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const Text(
                          "تفاصيل الحساب البنكي",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "قم بإدارة حسابك البنكي لاستقبال الأرباح والمدفوعات.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),

                        // Status Alert
                        _buildStatusAlert(),
                        const SizedBox(height: 20),

                        // Card 1: Basic Info
                        _buildInfoCard(),
                        const SizedBox(height: 20),

                        // Card 2: Certificate
                        _buildCertificateCard(),
                        const SizedBox(height: 30),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (_isSaving || _isUploading) ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: rose600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            icon: _isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save),
                            label: Text(
                              _isSaving ? "جاري الحفظ..." : "حفظ البيانات",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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

  Widget _buildStatusAlert() {
    // إذا لم يكن هناك آيبان، لا نعرض الحالة
    if (_details.iban.isEmpty) return const SizedBox();

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String description;

    switch (_details.status) {
      case 'approved':
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        title = "الحساب موثق";
        description = "بياناتك البنكية موثقة وجاهزة لاستقبال التحويلات.";
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        title = "تم رفض البيانات";
        description = "السبب: ${_details.rejectionReason ?? 'يرجى التأكد من صحة البيانات ووضوح الشهادة.'}";
        break;
      default: // pending
        bgColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade200;
        textColor = Colors.amber.shade800;
        icon = Icons.access_time_filled;
        title = "قيد المراجعة";
        description = "جاري مراجعة بياناتك البنكية من قبل الإدارة.";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: textColor, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: rose500),
              const SizedBox(width: 8),
              const Text("المعلومات الأساسية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          Text("يرجى إدخال البيانات كما هي في شهادة الآيبان", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 20),

          // Bank Name
          _buildTextField("اسم البنك", _bankNameCtrl, "مثال: مصرف الراجحي", Icons.account_balance),
          const SizedBox(height: 16),

          // Holder Name
          _buildTextField("اسم صاحب الحساب", _holderNameCtrl, "الاسم الثلاثي كما في البطاقة", Icons.person),
          const SizedBox(height: 16),

          // IBAN
          _buildTextField("رقم الآيبان (IBAN)", _ibanCtrl, "SA00 0000 0000 0000 0000 0000", Icons.credit_card, isLtr: true),
          const Padding(
            padding: EdgeInsets.only(top: 5, right: 5),
            child: Text("يجب أن يبدأ بـ SA ويتكون من 24 خانة", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          const SizedBox(height: 16),

          // Account Number
          _buildTextField("رقم الحساب (اختياري)", _accountNumberCtrl, "رقم الحساب المحلي", Icons.numbers, isOptional: true),
        ],
      ),
    );
  }

  Widget _buildCertificateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: rose500),
              const SizedBox(width: 8),
              const Text("شهادة الآيبان", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          Text("يرجى رفع صورة واضحة لشهادة الآيبان", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _isUploading ? null : _handleUpload,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), // استخدمنا solid لعدم وجود dotted_border
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isUploading
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: rose500),
                        const SizedBox(height: 10),
                        const Text("جاري الرفع..."),
                      ],
                    ))
                  : _details.ibanCertificateUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: _details.ibanCertificateUrl,
                                fit: BoxFit.contain,
                                placeholder: (c, u) => Container(color: Colors.grey.shade100),
                              ),
                              Container(
                                color: Colors.black.withOpacity(0.3),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green, size: 40),
                                      Text("تم رفع الملف", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text("انقر للاستبدال", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(color: rose50, shape: BoxShape.circle),
                              child: Icon(Icons.cloud_upload, color: rose500, size: 30),
                            ),
                            const SizedBox(height: 10),
                            const Text("انقر للرفع", style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text("PNG, JPG (الحد الأقصى 5MB)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, IconData icon, {bool isLtr = false, bool isOptional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
          validator: (val) {
            if (!isOptional && (val == null || val.isEmpty)) return "هذا الحقل مطلوب";
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            suffixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: rose500)),
          ),
        ),
      ],
    );
  }
}