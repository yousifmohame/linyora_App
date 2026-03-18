import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import 'package:linyora_project/features/models/bank/models/bank_details_model.dart';
import 'package:linyora_project/features/models/bank/services/bank_service.dart';

class InfluencerBankSettingsScreen extends StatefulWidget {
  const InfluencerBankSettingsScreen({Key? key}) : super(key: key);

  @override
  State<InfluencerBankSettingsScreen> createState() =>
      _ModelBankSettingsScreenState();
}

class _ModelBankSettingsScreenState
    extends State<InfluencerBankSettingsScreen> {
  final BankService _service = BankService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  BankDetails? _details;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  late TextEditingController _bankNameController;
  late TextEditingController _holderNameController;
  late TextEditingController _ibanController;
  late TextEditingController _accountNumberController;

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
      _holderNameController = TextEditingController(
        text: data.accountHolderName,
      );
      _ibanController = TextEditingController(text: data.iban);
      _accountNumberController = TextEditingController(
        text: data.accountNumber,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ تمرير l10n
  Future<void> _uploadCertificate(AppLocalizations l10n) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await _service.uploadCertificate(File(file.path));
      setState(() => _details!.ibanCertificateUrl = url);
      _showMessage(l10n.certificateUploadedSuccess); // ✅ مترجم
    } catch (e) {
      _showMessage(l10n.fileUploadFailed, isError: true); // ✅ مترجم
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ✅ تمرير l10n
  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    if (_details?.ibanCertificateUrl == null) {
      _showMessage(l10n.pleaseUploadIbanCertificate, isError: true); // ✅ مترجم
      return;
    }

    setState(() => _isSaving = true);

    _details!.bankName = _bankNameController.text;
    _details!.accountHolderName = _holderNameController.text;
    _details!.iban = _ibanController.text;
    _details!.accountNumber = _accountNumberController.text;

    try {
      await _service.saveBankDetails(_details!);
      _showMessage(l10n.dataSavedUnderReview); // ✅ مترجم
      _fetchDetails();
    } catch (e) {
      _showMessage(l10n.saveFailed, isError: true); // ✅ مترجم
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.shade50.withOpacity(0.3),
                  Colors.purple.shade50.withOpacity(0.3),
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeader(l10n), // ✅ تمرير الترجمة
                    const SizedBox(height: 20),

                    // Status Alert
                    if (_details?.status == 'pending')
                      _buildAlert(
                        l10n.accountUnderReview,
                        l10n.accountUnderReviewDesc,
                        Colors.amber,
                        Icons.access_time,
                      ) // ✅ مترجم
                    else if (_details?.status == 'rejected')
                      _buildAlert(
                        l10n.dataRejected,
                        _details?.rejectionReason ?? l10n.pleaseReviewAndRetry,
                        Colors.red,
                        Icons.error_outline,
                      ) // ✅ مترجم
                    else if (_details?.status == 'approved')
                      _buildAlert(
                        l10n.accountActivated,
                        l10n.bankDetailsVerified,
                        Colors.green,
                        Icons.check_circle,
                      ), // ✅ مترجم

                    const SizedBox(height: 20),

                    _buildCard(
                      title:
                          l10n.basicInfoTitle, // ✅ مترجم (استخدمناها في شاشة إضافة المنتج)
                      icon: Icons.account_balance,
                      children: [
                        _buildTextField(
                          l10n.bankName,
                          _bankNameController,
                          l10n,
                          icon: Icons.account_balance,
                          hint: l10n.bankNameHint,
                        ), // ✅ مترجم
                        const SizedBox(height: 16),
                        _buildTextField(
                          l10n.accountHolderName,
                          _holderNameController,
                          l10n,
                          icon: Icons.person,
                          hint: l10n.accountHolderNameHint,
                        ), // ✅ مترجم
                        const SizedBox(height: 16),
                        _buildTextField(
                          l10n.ibanNumber,
                          _ibanController,
                          l10n,
                          icon: Icons.credit_card,
                          hint: "SA00 0000...",
                          isLTR: true,
                        ), // ✅ مترجم
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 4,
                            right: 8,
                            left: 8,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              l10n.ibanCondition,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ), // ✅ مترجم
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          l10n.accountNumberOptional,
                          _accountNumberController,
                          l10n,
                          icon: Icons.numbers,
                          hint: l10n.localAccountNumberHint,
                        ), // ✅ مترجم
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildCard(
                      title: l10n.ibanCertificate, // ✅ مترجم
                      icon: Icons.file_present,
                      children: [
                        InkWell(
                          onTap:
                              _isUploading
                                  ? null
                                  : () =>
                                      _uploadCertificate(l10n), // ✅ تمرير l10n
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(
                                color: Colors.grey.shade300,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                _isUploading
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : _details?.ibanCertificateUrl != null
                                    ? Column(
                                      children: [
                                        Container(
                                          height: 150,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            image: DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                _details!.ibanCertificateUrl!,
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              l10n.fileUploadedSuccess,
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ), // ✅ مترجم
                                          ],
                                        ),
                                        Text(
                                          l10n.clickToReplace,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ), // ✅ مترجم
                                      ],
                                    )
                                    : Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.pink.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.cloud_upload,
                                            color: Colors.pink,
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          l10n.clickToUpload,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ), // ✅ مترجم
                                        Text(
                                          l10n.clearIbanImage,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ), // ✅ مترجم
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_isSaving || _isUploading)
                                ? null
                                : () => _save(l10n), // ✅ تمرير l10n
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _roseColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                        label: Text(
                          l10n.updateDataBtn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ), // ✅ مترجم (تمت إضافتها في العناوين)
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

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance, color: _roseColor, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.bankDetailsTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ), // ✅ مترجم
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.manageBankAccountDesc,
          style: const TextStyle(color: Colors.grey),
        ), // ✅ مترجم
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_roseColor, _purpleColor]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    AppLocalizations l10n, {
    IconData? icon,
    String? hint,
    bool isLTR = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textDirection:
              isLTR ? TextDirection.ltr : null, // تحديد الاتجاه حسب اللغة
          textAlign: isLTR ? TextAlign.left : TextAlign.start,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
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
          ),
          validator:
              (val) =>
                  val!.isEmpty && !label.contains(l10n.optionalWord)
                      ? l10n.requiredFieldMsg
                      : null, // ✅ ديناميكي
        ),
      ],
    );
  }

  Widget _buildAlert(String title, String msg, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  msg,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
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
}
