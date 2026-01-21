import 'package:flutter/material.dart';
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

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String? _selectedCategory;

  // Data State
  List<PackageTier> _tiers = [];
  bool _isLoading = false;

  // Colors
  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  // Categories Options (يمكن جلبها من API لاحقاً)
  final List<String> _categories = [
    'جلسة تصوير',
    'فيديو ترويجي',
    'مراجعة منتج',
    'حضور فعالية',
    'إعلان ستوري',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    if (widget.packageToEdit != null) {
      // وضع التعديل
      _titleController = TextEditingController(
        text: widget.packageToEdit!.title,
      );
      _descController = TextEditingController(
        text: widget.packageToEdit!.description,
      );
      _selectedCategory = widget.packageToEdit!.category;

      // نسخ الباقات لتجنب التعديل على الكائن الأصلي قبل الحفظ
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
      // وضع الإنشاء
      _titleController = TextEditingController();
      _descController = TextEditingController();
      // باقة افتراضية واحدة
      _tiers = [
        PackageTier(
          tierName: 'باقة أساسية',
          price: 100,
          deliveryDays: 1,
          revisions: 1,
          features: [''], // ميزة فارغة للبدء
        ),
      ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _addTier() {
    setState(() {
      _tiers.add(
        PackageTier(
          tierName: 'باقة جديدة',
          price: 0,
          deliveryDays: 1,
          revisions: 0,
          features: [''],
        ),
      );
    });
  }

  void _removeTier(int index) {
    if (_tiers.length > 1) {
      setState(() => _tiers.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يجب أن يحتوي العرض على باقة واحدة على الأقل"),
        ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // تجهيز البيانات
      final Map<String, dynamic> offerData = {
        'title': _titleController.text,
        'description': _descController.text,
        'category': _selectedCategory,
        'status': widget.packageToEdit?.status ?? 'active',
        // تحويل الباقات لـ JSON
        'tiers': _tiers.map((t) => t.toJson()).toList(),
      };

      if (widget.packageToEdit != null) {
        await _service.updateOffer(widget.packageToEdit!.id, offerData);
      } else {
        await _service.createOffer(offerData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم الحفظ بنجاح ✅"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // العودة مع نتيجة true لتحديث القائمة
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          widget.packageToEdit == null ? "إضافة عرض جديد" : "تعديل العرض",
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
            onPressed: _isLoading ? null : _submit,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      "حفظ",
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
              // 1. المعلومات الأساسية
              _buildSectionTitle("تفاصيل العرض", Icons.info_outline),
              const SizedBox(height: 16),
              _buildBasicInfoCard(),

              const SizedBox(height: 24),

              // 2. الباقات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle("الباقات والأسعار", Icons.layers_outlined),
                  TextButton.icon(
                    onPressed: _addTier,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("إضافة مستوى"),
                    style: TextButton.styleFrom(foregroundColor: _roseColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...List.generate(_tiers.length, (index) => _buildTierCard(index)),

              const SizedBox(height: 40),

              // زر الحفظ السفلي (إضافي)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
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
                              : const Text(
                                "حفظ العرض",
                                style: TextStyle(
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

  Widget _buildBasicInfoCard() {
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
            validator: (v) => v!.isEmpty ? "العنوان مطلوب" : null,
            decoration: _inputDecoration(
              "عنوان العرض",
              "مثال: جلسة تصوير منتجات احترافية",
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items:
                _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
            validator: (v) => v == null ? "يرجى اختيار فئة" : null,
            decoration: _inputDecoration("الفئة", "اختر فئة العرض"),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            maxLines: 3,
            decoration: _inputDecoration(
              "الوصف",
              "اشرح تفاصيل العرض وما سيحصل عليه العميل...",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(int index) {
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
          // Header
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
                  "المستوى ${index + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                if (_tiers.length > 1)
                  InkWell(
                    onTap: () => _removeTier(index),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          // Inputs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  initialValue: tier.tierName,
                  onChanged: (v) => tier.tierName = v,
                  validator: (v) => v!.isEmpty ? "مطلوب" : null,
                  decoration: _inputDecoration("اسم الباقة", "مثال: أساسية"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: tier.price.toString(),
                        onChanged: (v) => tier.price = double.tryParse(v) ?? 0,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("السعر (ر.س)", "0"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: tier.deliveryDays.toString(),
                        onChanged:
                            (v) => tier.deliveryDays = int.tryParse(v) ?? 1,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("مدة التسليم (أيام)", "1"),
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
                    "عدد التعديلات",
                    "(-1 للتعديلات اللانهائية)",
                  ),
                ),

                const Divider(height: 24),

                // Features List
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "المميزات:",
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
                              hintText: "ميزة (مثال: فيديو بجودة 4K)",
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
                  label: const Text("إضافة ميزة"),
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
