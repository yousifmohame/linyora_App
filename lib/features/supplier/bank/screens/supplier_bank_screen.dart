import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

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

  final _bankNameCtrl = TextEditingController();
  final _holderNameCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _accountNumCtrl = TextEditingController();

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

  // ✅ تمرير l10n للسناك بار
  Future<void> _pickAndUploadImage(AppLocalizations l10n) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await _service.uploadCertificate(File(image.path));
      setState(() => _certificateUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.uploadCertificateSuccessMsg)),
      ); // ✅ مترجم
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.uploadFileFailedMsg)),
      ); // ✅ مترجم
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ✅ تمرير l10n للسناك بار
  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    if (_certificateUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseUploadIbanCertificateMsg)),
      ); // ✅ مترجم
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
        status: 'pending',
      );

      await _service.saveBankDetails(details);

      if (mounted) {
        setState(() => _status = 'pending');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dataSavedSuccessMsg)),
        ); // ✅ مترجم
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.saveFailedMsg))); // ✅ مترجم
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

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
                        _buildStatusAlert(l10n), // ✅ تمرير l10n
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance,
                                    color: Colors.pink,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.basicInformationLabel, // ✅ مترجم
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                l10n.bankNameLabel,
                                _bankNameCtrl,
                                l10n,
                                icon: Icons.museum,
                              ), // ✅ مترجم
                              const SizedBox(height: 16),
                              _buildTextField(
                                l10n.accountHolderNameLabel,
                                _holderNameCtrl,
                                l10n,
                                icon: Icons.person,
                              ), // ✅ مترجم
                              const SizedBox(height: 16),
                              _buildTextField(
                                l10n.ibanLabel,
                                _ibanCtrl,
                                l10n,
                                icon: Icons.credit_card,
                                hint: l10n.ibanHint,
                              ), // ✅ مترجم
                              const SizedBox(height: 16),
                              _buildTextField(
                                l10n.accountNumberOptionalLabel,
                                _accountNumCtrl,
                                l10n,
                                isRequired: false,
                              ), // ✅ مترجم
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.description,
                                    color: Colors.pink,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.ibanCertificateLabel, // ✅ مترجم
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              InkWell(
                                onTap:
                                    _isUploading
                                        ? null
                                        : () => _pickAndUploadImage(
                                          l10n,
                                        ), // ✅ تمرير l10n
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
                                              l10n,
                                            ), // ✅ تمرير l10n
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
                                              Text(
                                                l10n.tapToUploadCertificateImageMsg, // ✅ مترجم
                                                style: const TextStyle(
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

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isSaving
                                    ? null
                                    : () => _submit(l10n), // ✅ تمرير l10n
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
                              l10n.saveDataBtn, // ✅ مترجم (موجود مسبقاً)
                              style: const TextStyle(
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

  Widget _buildFilePreview(String url, AppLocalizations l10n) {
    bool isPdf = url.toLowerCase().contains('.pdf');

    if (isPdf) {
      return Container(
        color: Colors.red.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              l10n.pdfFileLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ), // ✅ مترجم
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                url.split('/').last,
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
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder:
            (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget:
            (context, url, error) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                Text(l10n.cannotLoadImageMsg), // ✅ مترجم
              ],
            ),
      );
    }
  }

  Widget _buildStatusAlert(AppLocalizations l10n) {
    Color color;
    IconData icon;
    String title;
    String desc;

    if (_status == 'approved') {
      color = Colors.green;
      icon = Icons.check_circle;
      title = l10n.accountVerifiedTitle; // ✅ مترجم (موجود مسبقاً)
      desc = l10n.accountVerifiedDesc; // ✅ مترجم (موجود مسبقاً)
    } else if (_status == 'rejected') {
      color = Colors.red;
      icon = Icons.error;
      title = l10n.dataRejectedTitle; // ✅ مترجم (موجود مسبقاً)
      desc =
          "${l10n.reasonPrefix}${_rejectionReason ?? l10n.notAvailable}"; // ✅ مترجم ومدمج (موجود مسبقاً)
    } else {
      color = Colors.amber;
      icon = Icons.access_time_filled;
      title = l10n.underReviewTitle; // ✅ مترجم (موجود مسبقاً)
      desc = l10n.bankDataUnderReviewDesc; // ✅ مترجم (موجود مسبقاً)
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
    TextEditingController controller,
    AppLocalizations l10n, {
    IconData? icon,
    String? hint,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      validator:
          isRequired
              ? (v) => v!.isEmpty ? l10n.requiredField : null
              : null, // ✅ مترجم (موجود مسبقاً)
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
