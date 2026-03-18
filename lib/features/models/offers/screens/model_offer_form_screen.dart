import 'package:flutter/material.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import 'package:linyora_project/features/models/offers/models/offer_models.dart';
import 'package:linyora_project/features/models/offers/services/offers_service.dart';

class ModelOfferFormScreen extends StatefulWidget {
  final ServicePackage? packageToEdit;
  const ModelOfferFormScreen({Key? key, this.packageToEdit}) : super(key: key);

  @override
  State<ModelOfferFormScreen> createState() => _ModelOfferFormScreenState();
}

class _ModelOfferFormScreenState extends State<ModelOfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final OffersService _service = OffersService();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  String? _selectedCategory;

  List<PackageTier> _tiers = [];
  bool _isLoading = false;

  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  late List<String>
  _categories; // سيتم تهيئتها لاحقاً داخل build للوصول للترجمة

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // 💡 تأجيل تعيين الباقة الافتراضية حتى يتم جلب l10n
    if (widget.packageToEdit != null) {
      _titleController = TextEditingController(
        text: widget.packageToEdit!.title,
      );
      _descController = TextEditingController(
        text: widget.packageToEdit!.description,
      );
      _selectedCategory = widget.packageToEdit!.category;
      _tiers =
          widget.packageToEdit!.tiers
              .map(
                (t) => PackageTier(
                  id: t.id,
                  tierName: t.tierName,
                  price: t.price,
                  deliveryDays: t.deliveryDays,
                  revisions: t.revisions,
                  features: List.from(t.features),
                ),
              )
              .toList();
    } else {
      _titleController = TextEditingController();
      _descController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addTier(AppLocalizations l10n) {
    setState(() {
      _tiers.add(
        PackageTier(
          tierName: l10n.newPackageName, // ✅ مترجم
          price: 0,
          deliveryDays: 1,
          revisions: 0,
          features: [''],
        ),
      );
    });
  }

  void _removeTier(int index, AppLocalizations l10n) {
    if (_tiers.length > 1) {
      setState(() => _tiers.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.atLeastOnePackageMsg)), // ✅ مترجم
      );
    }
  }

  void _addFeatureToTier(int tierIndex) {
    setState(() {
      _tiers[tierIndex].features.add('');
    });
  }

  void _removeFeatureFromTier(int tierIndex, int featureIndex) {
    setState(() {
      _tiers[tierIndex].features.removeAt(featureIndex);
    });
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> offerData = {
        'title': _titleController.text,
        'description': _descController.text,
        'category': _selectedCategory,
        'status': widget.packageToEdit?.status ?? 'active',
        'tiers': _tiers.map((t) => t.toJson()).toList(),
      };

      if (widget.packageToEdit != null) {
        await _service.updateOffer(widget.packageToEdit!.id, offerData);
      } else {
        await _service.createOffer(offerData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${l10n.savedSuccessfullyMsg} ✅"), // ✅ مترجم
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${l10n.errorOccurredMsg}$e"),
            backgroundColor: Colors.red,
          ), // ✅ مترجم
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    // تهيئة التصنيفات المترجمة والباقة الافتراضية هنا لتكون معتمدة على اللغة
    _categories = [
      l10n.photoSessionCategory,
      l10n.promoVideoCategory,
      l10n.productReviewCategory,
      l10n.eventAttendanceCategory,
      l10n.storyAdCategory,
      l10n.otherCategory,
    ];

    if (_tiers.isEmpty && widget.packageToEdit == null) {
      _tiers = [
        PackageTier(
          tierName: l10n.basicPackageName,
          price: 100,
          deliveryDays: 1,
          revisions: 1,
          features: [''],
        ),
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          widget.packageToEdit == null
              ? l10n.addNewOfferBtn
              : l10n.editOfferTitle, // ✅ مترجم
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _submit(l10n), // ✅ تمرير l10n
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      l10n.saveBtn, // ✅ مترجم
                      style: TextStyle(
                        color: _purpleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                l10n.offerDetailsSection,
                Icons.info_outline,
              ), // ✅ مترجم
              const SizedBox(height: 16),
              _buildBasicInfoCard(l10n), // ✅ تمرير l10n

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(
                    l10n.packagesAndPricesSection,
                    Icons.layers_outlined,
                  ), // ✅ مترجم
                  TextButton.icon(
                    onPressed: () => _addTier(l10n), // ✅ تمرير l10n
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addLevelBtn), // ✅ مترجم
                    style: TextButton.styleFrom(foregroundColor: _roseColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...List.generate(
                _tiers.length,
                (index) => _buildTierCard(index, l10n),
              ), // ✅ تمرير l10n

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _submit(l10n), // ✅ تمرير l10n
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                l10n.saveOfferBtn, // ✅ مترجم
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _purpleColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoCard(AppLocalizations l10n) {
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
        children: [
          TextFormField(
            controller: _titleController,
            validator:
                (v) =>
                    v!.isEmpty
                        ? l10n.requiredFieldMsg
                        : null, // ✅ مترجم (سابقاً)
            decoration: _inputDecoration(
              l10n.offerTitleLabel,
              l10n.offerTitleHint,
            ), // ✅ مترجم
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items:
                _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
            validator:
                (v) =>
                    v == null
                        ? l10n.requiredFieldMsg
                        : null, // ✅ مترجم (سابقاً)
            decoration: _inputDecoration(
              l10n.categoryLabel,
              l10n.chooseOfferCategoryHint,
            ), // ✅ مترجم
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            maxLines: 3,
            decoration: _inputDecoration(
              l10n.descriptionLabel,
              l10n.descriptionHint,
            ), // ✅ مترجم
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(int index, AppLocalizations l10n) {
    final tier = _tiers[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${l10n.levelLabel}${index + 1}", // ✅ مترجم
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                if (_tiers.length > 1)
                  InkWell(
                    onTap:
                        () => _removeTier(index, l10n), // ✅ تمرير الترجمة للخطأ
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  initialValue: tier.tierName,
                  onChanged: (v) => tier.tierName = v,
                  validator:
                      (v) =>
                          v!.isEmpty
                              ? l10n.requiredFieldMsg
                              : null, // ✅ مترجم (سابقاً)
                  decoration: _inputDecoration(
                    l10n.packageNameLabel,
                    l10n.packageNameHint,
                  ), // ✅ مترجم
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: tier.price.toString(),
                        onChanged: (v) => tier.price = double.tryParse(v) ?? 0,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          l10n.priceSALLabel,
                          "0",
                        ), // ✅ مترجم
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: tier.deliveryDays.toString(),
                        onChanged:
                            (v) => tier.deliveryDays = int.tryParse(v) ?? 1,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          l10n.deliveryDurationDaysLabel,
                          "1",
                        ), // ✅ مترجم
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: tier.revisions.toString(),
                  onChanged: (v) => tier.revisions = int.tryParse(v) ?? 0,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    l10n.revisionsNumberLabel,
                    l10n.revisionsHint,
                  ), // ✅ مترجم
                ),

                const Divider(height: 24),

                Align(
                  alignment:
                      Alignment
                          .centerRight, // أو left حسب اللغة (سنتجاهلها هنا ونعتمد على Directionality للتطبيق)
                  child: Text(
                    l10n.featuresLabel, // ✅ مترجم
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  tier.features.length,
                  (fIndex) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: tier.features[fIndex],
                            onChanged: (v) => tier.features[fIndex] = v,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 8,
                              ),
                              hintText: l10n.featureHint, // ✅ مترجم
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onPressed:
                              () => _removeFeatureFromTier(index, fIndex),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addFeatureToTier(index),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l10n.addFeatureBtn), // ✅ مترجم
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
