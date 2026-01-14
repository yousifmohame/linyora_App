import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // 🎨 مكتبة الألوان
import 'package:linyora_project/features/supplier/products/models/supplier_models.dart';
import 'package:linyora_project/features/supplier/products/services/supplier_products_service.dart';

class SupplierProductFormScreen extends StatefulWidget {
  final SupplierProduct? product;

  const SupplierProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<SupplierProductFormScreen> createState() =>
      _SupplierProductFormScreenState();
}

class _SupplierProductFormScreenState extends State<SupplierProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupplierProductsService _service = SupplierProductsService();
  final ImagePicker _picker = ImagePicker();

  late SupplierProduct _formData;
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  int? _uploadingVariantIndex; // لتتبع الرفع

  // 🎨 تعريف التدرج اللوني (أزرق - بنفسجي)
  final LinearGradient _mainGradient = const LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF9333EA)], // Blue to Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeData();
  }

  void _initializeData() {
    if (widget.product != null) {
      _formData = SupplierProduct(
        id: widget.product!.id,
        name: widget.product!.name,
        brand: widget.product!.brand,
        description: widget.product!.description,
        variants:
            widget.product!.variants
                .map(
                  (v) => SupplierVariant(
                    id: v.id,
                    color: v.color,
                    costPrice: v.costPrice,
                    stockQuantity: v.stockQuantity,
                    images: List.from(v.images),
                  ),
                )
                .toList(),
        categoryIds: List.from(widget.product!.categoryIds),
      );
    } else {
      _formData = SupplierProduct(
        name: '',
        brand: '',
        description: '',
        variants: [
          SupplierVariant(
            color: '#000000',
            costPrice: 0,
            stockQuantity: 0,
            images: [],
          ),
        ],
        categoryIds: [],
      );
    }
  }

  Future<void> _loadCategories() async {
    final cats = await _service.getCategories();
    if (mounted)
      setState(() {
        _categories = cats;
        _isCategoriesLoading = false;
      });
  }

  // --- منطق الصور ---
  Future<void> _pickAndUploadImage(int variantIndex) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _uploadingVariantIndex = variantIndex);

    try {
      String url = await _service.uploadImage(File(image.path));
      setState(() {
        _formData.variants[variantIndex].images.add(url);
        _uploadingVariantIndex = null;
      });
    } catch (e) {
      setState(() => _uploadingVariantIndex = null);
      _showErrorSnackBar("فشل رفع الصورة: $e");
    }
  }

  void _removeImage(int variantIndex, String url) {
    setState(() {
      _formData.variants[variantIndex].images.remove(url);
    });
  }

  // --- منطق الحفظ ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _service.saveProduct(_formData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("تم الحفظ بنجاح ✅"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("خطأ: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 🎨 تحويل Hex String إلى Color
  Color _getColorFromHex(String hexColor) {
    try {
      hexColor = hexColor.replaceAll("#", "");
      if (hexColor.length == 6) hexColor = "FF$hexColor";
      return Color(int.parse("0x$hexColor"));
    } catch (e) {
      return Colors.black;
    }
  }

  // 🎨 تحويل Color إلى Hex String
  String _getHexFromColor(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.product == null ? "إضافة منتج جديد" : "تعديل المنتج",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: _mainGradient),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. المعلومات الأساسية (Accordion 1)
              _buildAccordionSection(
                title: "المعلومات الأساسية",
                icon: Icons.info_outline,
                isExpanded: true,
                children: [
                  _buildTextField(
                    "اسم المنتج",
                    (v) => _formData.name = v,
                    initial: _formData.name,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "الماركة",
                    (v) => _formData.brand = v,
                    initial: _formData.brand,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "الوصف",
                    (v) => _formData.description = v,
                    initial: _formData.description,
                    maxLines: 4,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. التصنيفات (Accordion 2)
              _buildAccordionSection(
                title: "التصنيفات",
                icon: Icons.category_outlined,
                children: [
                  InkWell(
                    onTap: _showCategoryDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.list, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formData.categoryIds.isEmpty
                                  ? "اضغط لاختيار التصنيفات..."
                                  : "تم اختيار ${_formData.categoryIds.length} تصنيف",
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. المتغيرات والألوان (Accordion 3 - Dynamic)
              _buildAccordionSection(
                title: "الأصناف والألوان (Variants)",
                icon: Icons.palette_outlined,
                isExpanded: true,
                trailing: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _formData.variants.add(
                        SupplierVariant(
                          color: '#000000',
                          costPrice: 0,
                          stockQuantity: 0,
                          images: [],
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text(
                    "إضافة لون",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.2),
                  ),
                ),
                children:
                    _formData.variants.asMap().entries.map((entry) {
                      return _buildVariantCard(entry.key, entry.value);
                    }).toList(),
              ),

              const SizedBox(height: 100), // مساحة للزر العائم
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.transparent, // شفاف لاستخدام التدرج
            shadowColor: Colors.transparent,
          ).copyWith(
            // خدعة لتطبيق التدرج على الزر
            backgroundBuilder:
                (ctx, states, child) => Container(
                  decoration: BoxDecoration(
                    gradient: _mainGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: child,
                ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    "حفظ ونشر المنتج",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }

  // --- Widgets ---

  // 📦 Accordion Wrapper
  Widget _buildAccordionSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isExpanded = false,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          trailing: trailing, // زر مخصص في الرأس
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: children,
        ),
      ),
    );
  }

  // 🎨 بطاقة المتغير (Variant Card)
  Widget _buildVariantCard(int index, SupplierVariant variant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50.withOpacity(0.5),
            Colors.purple.shade50.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 🌈 Color Picker
              Expanded(
                child: InkWell(
                  onTap: () => _showColorPickerDialog(index, variant.color),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getColorFromHex(variant.color),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "اختر اللون",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // زر الحذف
              if (_formData.variants.length > 1)
                IconButton(
                  onPressed:
                      () => setState(() => _formData.variants.removeAt(index)),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  "التكلفة (ر.س)",
                  (v) => variant.costPrice = double.tryParse(v) ?? 0,
                  initial: variant.costPrice.toString(),
                  isNum: true,
                  isSmall: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  "الكمية",
                  (v) => variant.stockQuantity = int.tryParse(v) ?? 0,
                  initial: variant.stockQuantity.toString(),
                  isNum: true,
                  isSmall: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // منطقة الصور
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              children: [
                // زر إضافة صورة
                InkWell(
                  onTap: () => _pickAndUploadImage(index),
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child:
                        _uploadingVariantIndex == index
                            ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Colors.blue.shade600,
                                ),
                                Text(
                                  "إضافة",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
                // عرض الصور
                ...variant.images
                    .map(
                      (imgUrl) => Stack(
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: imgUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 10,
                            child: InkWell(
                              // onTap: () => _removeImage(index, imgUrl),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // نافذة اختيار اللون
  void _showColorPickerDialog(int index, String currentColor) {
    Color pickerColor = _getColorFromHex(currentColor);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('اختر لون المنتج'),
            content: SingleChildScrollView(
              child: BlockPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) {
                  setState(() {
                    _formData.variants[index].color = _getHexFromColor(color);
                  });
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(
    String label,
    Function(String) onChanged, {
    String? initial,
    int maxLines = 1,
    bool isNum = false,
    bool isSmall = false,
  }) {
    return TextFormField(
      initialValue: initial,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      validator: (v) => v!.isEmpty ? "هذا الحقل مطلوب" : null,
      style: TextStyle(fontSize: isSmall ? 14 : 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: isSmall ? 13 : 15,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isSmall ? 12 : 16,
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
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  // نفس نافذة التصنيفات السابقة...
  void _showCategoryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            expand: false,
            builder:
                (_, scrollController) => ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      "اختر التصنيفات",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isCategoriesLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ..._categories.map((c) => _buildCategoryNode(c)).toList(),
                  ],
                ),
          ),
    );
  }

  Widget _buildCategoryNode(Category cat) {
    bool isSelected = _formData.categoryIds.contains(cat.id);
    return Column(
      children: [
        CheckboxListTile(
          title: Text(
            cat.name,
            style: TextStyle(
              fontWeight:
                  cat.children.isNotEmpty ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          value: isSelected,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _formData.categoryIds.add(cat.id);
              } else {
                _formData.categoryIds.remove(cat.id);
              }
            });
            // إذا كان تصنيف رئيسي، قد ترغب في تحديث الواجهة لإعادة رسم النافذة
            Navigator.pop(context);
            _showCategoryDialog();
          },
          activeColor: const Color(0xFFF105C6),
        ),
        if (cat.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              children: cat.children.map((c) => _buildCategoryNode(c)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "الأصناف (Variants)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _formData.variants.add(
                    SupplierVariant(
                      color: '',
                      costPrice: 0,
                      stockQuantity: 0,
                      images: [],
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add_circle, color: Color(0xFFF105C6)),
              label: const Text(
                "إضافة لون",
                style: TextStyle(color: Color(0xFFF105C6)),
              ),
            ),
          ],
        ),
        ..._formData.variants.asMap().entries.map((entry) {
          int i = entry.key;
          SupplierVariant v = entry.value;
          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "اللون",
                        (val) => v.color = val,
                        initial: v.color,
                      ),
                    ),
                    if (_formData.variants.length > 1)
                      IconButton(
                        onPressed:
                            () =>
                                setState(() => _formData.variants.removeAt(i)),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "التكلفة",
                        (val) => v.costPrice = double.tryParse(val) ?? 0,
                        initial: v.costPrice.toString(),
                        isNum: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        "الكمية",
                        (val) => v.stockQuantity = int.tryParse(val) ?? 0,
                        initial: v.stockQuantity.toString(),
                        isNum: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // صور المتغير
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // زر الرفع
                      InkWell(
                        onTap: () => _pickAndUploadImage(i),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child:
                              _uploadingVariantIndex == i
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : const Icon(
                                    Icons.add_a_photo,
                                    color: Colors.grey,
                                  ),
                        ),
                      ),
                      // الصور المرفوعة
                      ...v.images
                          .map(
                            (imgUrl) => Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: imgUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: InkWell(
                                    onTap: () => _removeImage(i, imgUrl),
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.red,
                                      child: Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
