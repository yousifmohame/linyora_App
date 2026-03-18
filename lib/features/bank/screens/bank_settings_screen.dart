import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

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

  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _holderNameCtrl = TextEditingController();
  final TextEditingController _ibanCtrl = TextEditingController();
  final TextEditingController _accountNumberCtrl = TextEditingController();

  BankDetails _details = BankDetails();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

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

  // ✅ تمرير l10n
  Future<void> _handleUpload(AppLocalizations l10n) async {
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
            SnackBar(
              content: Text(l10n.certificateUploadedSuccess),
              backgroundColor: Colors.green,
            ), // ✅ مترجم
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileUploadFailed),
            backgroundColor: Colors.red,
          ), // ✅ مترجم
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  // ✅ تمرير l10n
  Future<void> _handleSubmit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    _details.bankName = _bankNameCtrl.text;
    _details.accountHolderName = _holderNameCtrl.text;
    _details.iban = _ibanCtrl.text;
    _details.accountNumber = _accountNumberCtrl.text;

    setState(() => _isSaving = true);
    try {
      await _service.updateBankDetails(_details);
      await _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.dataSavedUnderReview),
          backgroundColor: Colors.green,
        ), // ✅ مترجم
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.saveFailed),
          backgroundColor: Colors.red,
        ), // ✅ مترجم
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

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
          child:
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: rose500))
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.bankAccountDetailsTitle, // ✅ مترجم
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.manageBankAccountDesc, // ✅ مترجم
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 20),

                          _buildStatusAlert(l10n), // ✅ تمرير l10n
                          const SizedBox(height: 20),

                          _buildInfoCard(l10n), // ✅ تمرير l10n
                          const SizedBox(height: 20),

                          _buildCertificateCard(l10n), // ✅ تمرير l10n
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_isSaving || _isUploading)
                                      ? null
                                      : () =>
                                          _handleSubmit(l10n), // ✅ تمرير l10n
                              style: ElevatedButton.styleFrom(
                                backgroundColor: rose600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
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
                                _isSaving
                                    ? l10n.savingMsg
                                    : l10n.saveDataBtn, // ✅ مترجم
                                style: const TextStyle(
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
        ),
      ),
    );
  }

  Widget _buildStatusAlert(AppLocalizations l10n) {
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
        title = l10n.accountVerifiedTitle; // ✅ مترجم
        description = l10n.accountVerifiedDesc; // ✅ مترجم
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        title = l10n.dataRejectedTitle; // ✅ مترجم
        description =
            "${l10n.reasonPrefix}${_details.rejectionReason ?? l10n.pleaseEnsureCorrectDataMsg}"; // ✅ مترجم ومدمج
        break;
      default: // pending
        bgColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade200;
        textColor = Colors.amber.shade800;
        icon = Icons.access_time_filled;
        title = l10n.underReviewTitle; // ✅ مترجم
        description = l10n.bankDataUnderReviewDesc; // ✅ مترجم
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
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: rose500),
              const SizedBox(width: 8),
              Text(
                l10n.basicInfoTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ), // ✅ مترجم
            ],
          ),
          const SizedBox(height: 5),
          Text(
            l10n.enterDataAsInCertificateMsg,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ), // ✅ مترجم
          const SizedBox(height: 20),

          _buildTextField(
            l10n.bankName,
            _bankNameCtrl,
            l10n.bankNameHint,
            Icons.account_balance,
            l10n,
          ), // ✅ مترجم
          const SizedBox(height: 16),

          _buildTextField(
            l10n.accountHolderName,
            _holderNameCtrl,
            l10n.accountHolderNameHint,
            Icons.person,
            l10n,
          ), // ✅ مترجم
          const SizedBox(height: 16),

          _buildTextField(
            l10n.ibanNumber,
            _ibanCtrl,
            "SA00 0000 0000 0000 0000 0000",
            Icons.credit_card,
            l10n,
            isLtr: true,
          ), // ✅ مترجم
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 5, left: 5),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                l10n.ibanCondition,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ), // ✅ مترجم
            ),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            l10n.accountNumberOptional,
            _accountNumberCtrl,
            l10n.localAccountNumberHint,
            Icons.numbers,
            l10n,
            isOptional: true,
          ), // ✅ مترجم
        ],
      ),
    );
  }

  Widget _buildCertificateCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: rose500),
              const SizedBox(width: 8),
              Text(
                l10n.ibanCertificate,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ), // ✅ مترجم
            ],
          ),
          const SizedBox(height: 5),
          Text(
            l10n.pleaseUploadClearIbanImageMsg,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ), // ✅ مترجم
          const SizedBox(height: 20),

          GestureDetector(
            onTap:
                _isUploading ? null : () => _handleUpload(l10n), // ✅ تمرير l10n
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  _isUploading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: rose500),
                            const SizedBox(height: 10),
                            Text(l10n.uploadingMsg), // ✅ مترجم
                          ],
                        ),
                      )
                      : _details.ibanCertificateUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: _details.ibanCertificateUrl,
                              fit: BoxFit.contain,
                              placeholder:
                                  (c, u) =>
                                      Container(color: Colors.grey.shade100),
                            ),
                            Container(
                              color: Colors.black.withOpacity(0.3),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 40,
                                    ),
                                    Text(
                                      l10n.fileUploadedMsg,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ), // ✅ مترجم
                                    Text(
                                      l10n.clickToReplace,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ), // ✅ مترجم
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
                            decoration: BoxDecoration(
                              color: rose50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cloud_upload,
                              color: rose500,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.clickToUpload,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ), // ✅ مترجم
                          Text(
                            l10n.supportedImageFormatsMsg,
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
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon,
    AppLocalizations l10n, {
    bool isLtr = false,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textDirection:
              isLtr ? TextDirection.ltr : null, // ✅ ديناميكي حسب اللغة
          textAlign: isLtr ? TextAlign.left : TextAlign.start,
          validator: (val) {
            if (!isOptional && (val == null || val.isEmpty))
              return l10n.thisFieldIsRequiredMsg; // ✅ مترجم
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            suffixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              borderSide: BorderSide(color: rose500),
            ),
          ),
        ),
      ],
    );
  }
}
