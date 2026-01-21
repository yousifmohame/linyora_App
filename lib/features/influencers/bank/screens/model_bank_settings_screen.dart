import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/models/bank/models/bank_details_model.dart';
import 'package:linyora_project/features/models/bank/services/bank_service.dart';



class InfluencerBankSettingsScreen extends StatefulWidget {
  const InfluencerBankSettingsScreen({Key? key}) : super(key: key);

  @override
  State<InfluencerBankSettingsScreen> createState() => _ModelBankSettingsScreenState();
}

class _ModelBankSettingsScreenState extends State<InfluencerBankSettingsScreen> {
  final BankService _service = BankService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  BankDetails? _details;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  // Controllers
  late TextEditingController _bankNameController;
  late TextEditingController _holderNameController;
  late TextEditingController _ibanController;
  late TextEditingController _accountNumberController;

  // Colors
  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getBankDetails();
      _details = data;
      
      _bankNameController = TextEditingController(text: data.bankName);
      _holderNameController = TextEditingController(text: data.accountHolderName);
      _ibanController = TextEditingController(text: data.iban);
      _accountNumberController = TextEditingController(text: data.accountNumber);

      setState(() => _isLoading = false);
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadCertificate() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await _service.uploadCertificate(File(file.path));
      setState(() => _details!.ibanCertificateUrl = url);
      _showMessage("تم رفع الشهادة بنجاح ✅");
    } catch (e) {
      _showMessage("فشل رفع الملف", isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_details?.ibanCertificateUrl == null) {
      _showMessage("يرجى رفع شهادة الآيبان", isError: true);
      return;
    }

    setState(() => _isSaving = true);
    
    // Update model
    _details!.bankName = _bankNameController.text;
    _details!.accountHolderName = _holderNameController.text;
    _details!.iban = _ibanController.text;
    _details!.accountNumber = _accountNumberController.text;

    try {
      await _service.saveBankDetails(_details!);
      _showMessage("تم حفظ البيانات وإرسالها للمراجعة ✅");
      _fetchDetails(); // تحديث الحالة
    } catch (e) {
      _showMessage("فشل الحفظ", isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade50.withOpacity(0.3), Colors.purple.shade50.withOpacity(0.3)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(top: -50, right: -50, child: _buildBlurBlob(Colors.pink.shade200)),
          Positioned(bottom: -50, left: -50, child: _buildBlurBlob(Colors.purple.shade200)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),

                    // Status Alert
                    if (_details?.status == 'pending')
                      _buildAlert("الحساب قيد المراجعة", "جاري مراجعة بياناتك البنكية، سيتم تفعيل الحساب قريباً.", Colors.amber, Icons.access_time)
                    else if (_details?.status == 'rejected')
                      _buildAlert("تم رفض البيانات", _details?.rejectionReason ?? "يرجى مراجعة البيانات وإعادة المحاولة.", Colors.red, Icons.error_outline)
                    else if (_details?.status == 'approved')
                      _buildAlert("الحساب مفعل", "تم التحقق من بياناتك البنكية بنجاح.", Colors.green, Icons.check_circle),

                    const SizedBox(height: 20),

                    // 1. Basic Info Card
                    _buildCard(
                      title: "المعلومات الأساسية",
                      icon: Icons.account_balance,
                      children: [
                        _buildTextField("اسم البنك", _bankNameController, icon: Icons.account_balance, hint: "مثال: مصرف الراجحي"),
                        const SizedBox(height: 16),
                        _buildTextField("اسم صاحب الحساب", _holderNameController, icon: Icons.person, hint: "الاسم الثلاثي كما في البطاقة"),
                        const SizedBox(height: 16),
                        _buildTextField("رقم الآيبان (IBAN)", _ibanController, icon: Icons.credit_card, hint: "SA00 0000...", isLTR: true),
                        const Padding(
                          padding: EdgeInsets.only(top: 4, right: 8),
                          child: Align(alignment: Alignment.centerRight, child: Text("يجب أن يبدأ بـ SA ويتكون من 24 خانة.", style: TextStyle(fontSize: 10, color: Colors.grey))),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField("رقم الحساب (اختياري)", _accountNumberController, icon: Icons.numbers, hint: "رقم الحساب المحلي"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 2. Certificate Upload
                    _buildCard(
                      title: "شهادة الآيبان",
                      icon: Icons.file_present,
                      children: [
                        InkWell(
                          onTap: _isUploading ? null : _uploadCertificate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), // Dashed effect can be done with custom painter
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isUploading
                                ? const Center(child: CircularProgressIndicator())
                                : _details?.ibanCertificateUrl != null
                                    ? Column(
                                        children: [
                                          Container(
                                            height: 150,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              image: DecorationImage(image: CachedNetworkImageProvider(_details!.ibanCertificateUrl!), fit: BoxFit.cover),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: Colors.green, size: 16), SizedBox(width: 4), Text("تم رفع الملف بنجاح", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
                                          const Text("انقر للاستبدال", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle), child: const Icon(Icons.cloud_upload, color: Colors.pink, size: 30)),
                                          const SizedBox(height: 10),
                                          const Text("انقر للرفع", style: TextStyle(fontWeight: FontWeight.bold)),
                                          const Text("صورة واضحة لشهادة الآيبان", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: (_isSaving || _isUploading) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _roseColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                        label: const Text("حفظ البيانات", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.account_balance, color: _roseColor, size: 28)),
            const SizedBox(width: 12),
            const Text("التفاصيل البنكية", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        const Text("إدارة حسابك البنكي لاستقبال الأرباح", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [_roseColor, _purpleColor]), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
          ),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, String? hint, bool isLTR = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textDirection: isLTR ? TextDirection.ltr : TextDirection.rtl,
          textAlign: isLTR ? TextAlign.left : TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _purpleColor)),
          ),
          validator: (val) => val!.isEmpty && !label.contains("اختياري") ? "مطلوب" : null,
        ),
      ],
    );
  }

  Widget _buildAlert(String title, String msg, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(msg, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 200, height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(color: Colors.transparent)),
    );
  }
}