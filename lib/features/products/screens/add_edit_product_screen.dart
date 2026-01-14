import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart'; // تأكد من وجود هذه المكتبة
import 'package:linyora_project/models/product_model.dart';
import 'package:linyora_project/features/products/services/product_service.dart';
import 'package:linyora_project/features/categories/services/category_service.dart';
import 'package:linyora_project/models/category_model.dart';

// تعريف الألوان المسبقة
const List<Map<String, dynamic>> kPredefinedColors = [
  {'name': 'red', 'value': Color(0xFFFF0000)},
  {'name': 'blue', 'value': Color(0xFF0000FF)},
  {'name': 'green', 'value': Color(0xFF00FF00)},
  {'name': 'yellow', 'value': Color(0xFFFFFF00)},
  {'name': 'black', 'value': Color(0xFF000000)},
  {'name': 'white', 'value': Color(0xFFFFFFFF)},
  {'name': 'gray', 'value': Color(0xFF808080)},
  {'name': 'gold', 'value': Color(0xFFFFD700)},
  {'name': 'purple', 'value': Color(0xFF800080)},
  {'name': 'pink', 'value': Color(0xFFFFC0CB)},
];

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final ImagePicker _picker = ImagePicker();

  // Basic Info Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _brandController;

  bool _isActive = true;
  bool _isDropshipping = false; // ✅ متغير التحكم في الدروب شيبينج
  List<int> _selectedCategoryIds = [];

  // Variants State
  List<Map<String, dynamic>> _variants = [];

  // UI State
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;

  List<CategoryModel> _allCategories = [];

  @override
  void initState() {
    super.initState();

    // 1. التحقق من نوع المنتج
    if (widget.product != null) {
      _isDropshipping = widget.product!.isDropshipping;
    }

    _initializeData();

    // ✅ الحل: جلب الفئات دائماً لضمان عرض أسمائها (حتى لو كانت للقراءة فقط)
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _categoryService.getAllCategories();

      if (mounted) {
        setState(() {
          _allCategories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  String _getCategoryNameById(int id) {
    // دالة مساعدة للبحث داخل الشجرة
    CategoryModel? findRecursive(List<CategoryModel> list) {
      for (var cat in list) {
        if (cat.id == id) return cat; // وجدناه في هذا المستوى

        if (cat.children.isNotEmpty) {
          final foundInChild = findRecursive(cat.children);
          if (foundInChild != null) return foundInChild; // وجدناه في الابن
        }
      }
      return null;
    }

    final cat = findRecursive(_allCategories);
    return cat?.name ?? 'Unknown ($id)';
  }

  void _initializeData() {
    if (widget.product != null) {
      if (widget.product!.categoryIds != null) {
        // ✅ التأكد من تحويل القيم إلى int بشكل صريح
        _selectedCategoryIds =
            widget.product!.categoryIds!
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .where((e) => e > 0)
                .toList();
      }
    } else {}

    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _brandController = TextEditingController(text: widget.product?.brand ?? '');

    if (widget.product?.categoryIds != null) {
      _selectedCategoryIds = List.from(widget.product!.categoryIds!);
    }

    if (widget.product != null &&
        widget.product!.variants != null &&
        widget.product!.variants!.isNotEmpty) {
      _variants =
          widget.product!.variants!
              .map(
                (v) => {
                  'id': v.id,
                  'color': TextEditingController(text: v.color),
                  'price': TextEditingController(text: v.price.toString()),
                  'compare_at_price': TextEditingController(
                    text: v.compareAtPrice?.toString() ?? '',
                  ),
                  'stock': TextEditingController(
                    text: v.stockQuantity.toString(),
                  ),
                  'sku': TextEditingController(text: v.sku ?? ''),
                  'images': v.images ?? [],
                  'new_images': <File>[],
                },
              )
              .toList();
    } else {
      _addVariant();
    }
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'id': null,
        'color': TextEditingController(),
        'price': TextEditingController(),
        'compare_at_price': TextEditingController(),
        'stock': TextEditingController(),
        'sku': TextEditingController(),
        'images': [],
        'new_images': <File>[],
      });
    });
  }

  void _removeVariant(int index) {
    if (_variants.length > 1) {
      setState(() {
        _variants.removeAt(index);
      });
    }
  }

  Future<void> _pickImageForVariant(int index) async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        (_variants[index]['new_images'] as List<File>).addAll(
          images.map((x) => File(x.path)),
        );
      });
    }
  }

  String _generateSku(int index) {
    String namePart =
        _nameController.text.isNotEmpty
            ? _nameController.text
                .replaceAll(' ', '')
                .toUpperCase()
                .substring(
                  0,
                  _nameController.text.length > 3
                      ? 3
                      : _nameController.text.length,
                )
            : 'PROD';
    String colorPart =
        (_variants[index]['color'] as TextEditingController).text.isNotEmpty
            ? (_variants[index]['color'] as TextEditingController).text
                .toUpperCase()
                .substring(0, 3)
            : 'CLR';
    return '$namePart-$colorPart-${index + 1}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isDropshipping && _selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار فئة واحدة على الأقل')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<File> allNewImages = [];
      if (!_isDropshipping) {
        for (var v in _variants) {
          allNewImages.addAll(v['new_images'] as List<File>);
        }
      }

      final Map<String, dynamic> productData = {
        'name': _nameController.text,
        'description': _descController.text,
        'brand': _brandController.text,
        'status': _isActive ? 'active' : 'draft',
        'categoryIds': _selectedCategoryIds,
        'variants':
            _variants.map((v) {
              final priceText = (v['price'] as TextEditingController).text;
              final compareText =
                  (v['compare_at_price'] as TextEditingController).text;
              final stockText = (v['stock'] as TextEditingController).text;

              return {
                // ✅✅✅ هذا هو التعديل الهام جداً: إرسال الـ ID
                'id': v['id'],

                'color': (v['color'] as TextEditingController).text,
                'price': double.tryParse(priceText) ?? 0,
                'compare_at_price':
                    compareText.isEmpty ? null : double.tryParse(compareText),
                'stock_quantity': int.tryParse(stockText) ?? 0,
                'sku':
                    (v['sku'] as TextEditingController).text.isEmpty
                        ? _generateSku(_variants.indexOf(v))
                        : (v['sku'] as TextEditingController).text,
                'images': v['images'],
              };
            }).toList(),
      };

      bool success;
      if (widget.product == null) {
        success = await _productService.createProduct(
          productData,
          allNewImages,
        );
      } else {
        success = await _productService.updateProduct(
          widget.product!.id.toString(),
          productData,
          newImages: allNewImages,
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحفظ بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.product == null ? 'إضافة منتج' : 'تعديل المنتج'),
            if (_isDropshipping) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_download, size: 12, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      "Dropshipping",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body:
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_isDropshipping) _buildDropshippingAlert(),

                      _buildBasicInfoCard(),
                      const SizedBox(height: 24),

                      _buildVariantsCard(),

                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
    );
  }

  // --- Widgets ---

  Widget _buildDropshippingAlert() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "هذا منتج مستورد. يمكنك تعديل السعر والوصف فقط، بينما يتم مزامنة المخزون والصور تلقائياً من المورد.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueAccent,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified, color: Colors.pink),
              SizedBox(width: 8),
              Text(
                'المعلومات الأساسية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 30),

          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _nameController,
                  label: 'اسم المنتج',
                  icon: Icons.auto_awesome,
                  color: Colors.pink,
                  readOnly: _isDropshipping, // 🔒 قفل الاسم
                  hint: _isDropshipping ? "الاسم الأصلي من المورد" : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  controller: _brandController,
                  label: 'الماركة',
                  icon: Icons.trending_up,
                  color: Colors.purple,
                  readOnly: _isDropshipping, // 🔒 قفل الماركة
                ),
              ),
            ],
          ),

          if (!_isDropshipping) ...[
            const SizedBox(height: 16),
            _isLoadingCategories
                ? const LinearProgressIndicator()
                : _buildCategorySelector(),
          ],

          const SizedBox(height: 16),
          _buildInputField(
            controller: _descController,
            label: 'وصف المنتج',
            icon: Icons.description,
            color: Colors.blue,
            maxLines: 4,
            // الوصف عادة مسموح تعديله حتى في الدروب شيبينج لتحسين الـ SEO
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'حالة المنتج (نشط/مسودة)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: Colors.pink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.style, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'خيارات المنتج',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 30),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _variants.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final variant = _variants[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // زر الحذف يظهر فقط إذا لم يكن دروب شيبينج
                    if (!_isDropshipping && _variants.length > 1)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeVariant(index),
                        ),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: variant['color'],
                            label: 'اللون',
                            icon: Icons.palette,
                            color: Colors.amber,
                            readOnly: _isDropshipping, // 🔒 قفل اللون
                          ),
                        ),
                        if (!_isDropshipping) ...[
                          const SizedBox(width: 8),
                          // إخفاء اختيار الألوان في حالة الدروب شيبينج
                          SizedBox(
                            height: 30,
                            width: 100,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children:
                                  kPredefinedColors
                                      .map(
                                        (c) => InkWell(
                                          onTap: () {
                                            (variant['color']
                                                    as TextEditingController)
                                                .text = c['name'];
                                            setState(() {});
                                          },
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: c['value'],
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: variant['price'],
                            label: _isDropshipping ? 'سعر البيع' : 'السعر',
                            icon: Icons.attach_money,
                            color: Colors.green,
                            keyboardType: TextInputType.number,
                            // السعر دائماً قابل للتعديل
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            controller: variant['compare_at_price'],
                            label: 'السعر القديم',
                            icon: Icons.money_off,
                            color: Colors.blue,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: variant['stock'],
                      label: 'الكمية',
                      icon: Icons.inventory,
                      color: Colors.purple,
                      keyboardType: TextInputType.number,
                      readOnly: _isDropshipping, // 🔒 قفل الكمية
                      hint: _isDropshipping ? "تدار تلقائياً" : null,
                    ),

                    const SizedBox(height: 16),

                    // إذا دروب شيبينج، عرض الصور فقط (بدون تعديل)
                    _isDropshipping
                        ? _buildReadOnlyImages(variant['images'])
                        : _buildImagesSection(index),
                  ],
                ),
              );
            },
          ),

          // زر إضافة متغير يختفي في حالة الدروب شيبينج
          if (!_isDropshipping) ...[
            const SizedBox(height: 20),
            InkWell(
              onTap: _addVariant,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.amber.shade50,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'إضافة خيار جديد',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ويدجت صور للقراءة فقط (للدروب شيبينج)
  Widget _buildReadOnlyImages(List images) {
    if (images.isEmpty)
      return const Align(
        alignment: Alignment.centerRight,
        child: Text(
          "لا توجد صور متاحة من المورد.",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'صور المنتج (للعرض فقط)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder:
                (ctx, i) => Container(
                  width: 80,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey[100]),
                      errorWidget:
                          (c, u, e) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection(int index) {
    final variant = _variants[index];
    final existingImages = variant['images'] as List;
    final newImages = variant['new_images'] as List<File>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'صور الخيار',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              InkWell(
                onTap: () => _pickImageForVariant(index),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.grey[400],
                      ),
                      const Text(
                        'رفع صورة',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              ...newImages.map(
                (file) => Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () => setState(() => newImages.remove(file)),
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
              ),
              ...existingImages.map(
                (url) => Container(
                  width: 100,
                  margin: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // (نفس كود التصنيفات السابق)
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.category, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'الفئات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCategoryDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedCategoryIds.isEmpty
                        ? 'اختر الفئات...'
                        // ✅ هنا التغيير الجذري: نستخدم الدالة التكرارية بدلاً من البحث السطحي
                        : _selectedCategoryIds
                            .map((id) => _getCategoryNameById(id))
                            .join(', '),
                    style: TextStyle(
                      color:
                          _selectedCategoryIds.isEmpty
                              ? Colors.grey
                              : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (_selectedCategoryIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  _selectedCategoryIds.map((id) {
                    final cat = _allCategories.firstWhere(
                      (c) => c.id == id,
                      orElse:
                          () => CategoryModel(
                            id: id,
                            name: 'Unknown',
                            slug: '',
                            imageUrl: '',
                          ),
                    );
                    if (cat.name == 'Unknown') return const SizedBox();
                    return Chip(
                      label: Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                      backgroundColor: Colors.blue.shade50,
                      deleteIcon: const Icon(Icons.close, size: 12),
                      onDeleted:
                          () => setState(() => _selectedCategoryIds.remove(id)),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<CategoryModel> displayList = [];
            if (searchQuery.isNotEmpty) {
              void searchRecursive(List<CategoryModel> list) {
                for (var item in list) {
                  if (item.name.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ))
                    displayList.add(item);
                  if (item.children.isNotEmpty) searchRecursive(item.children);
                }
              }

              searchRecursive(_allCategories);
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "اختر الفئات",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'بحث...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (v) => setDialogState(() => searchQuery = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  SizedBox(
                    height: 350,
                    child:
                        searchQuery.isNotEmpty
                            ? _buildSearchResults(displayList, setDialogState)
                            : ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: _buildCategoryTree(
                                _allCategories,
                                0,
                                setDialogState,
                              ),
                            ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('تم'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildCategoryTree(
    List<CategoryModel> categories,
    int level,
    StateSetter setDialogState,
  ) {
    List<Widget> widgets = [];
    for (var cat in categories) {
      final isSelected = _selectedCategoryIds.contains(cat.id);
      widgets.add(
        InkWell(
          onTap: () {
            setState(() {
              if (isSelected)
                _selectedCategoryIds.remove(cat.id);
              else
                _selectedCategoryIds.add(cat.id);
            });
            setDialogState(() {});
          },
          child: Padding(
            padding: EdgeInsets.only(
              right: 16.0 + (level * 24.0),
              left: 16.0,
              top: 12,
              bottom: 12,
            ),
            child: Row(
              children: [
                if (level > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.subdirectory_arrow_left,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.white,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontWeight:
                          level == 0 ? FontWeight.bold : FontWeight.normal,
                      color: Colors.black87,
                      fontSize: level == 0 ? 14 : 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (cat.children.isNotEmpty)
        widgets.addAll(
          _buildCategoryTree(cat.children, level + 1, setDialogState),
        );
    }
    return widgets;
  }

  Widget _buildSearchResults(
    List<CategoryModel> list,
    StateSetter setDialogState,
  ) {
    if (list.isEmpty) return const Center(child: Text("لا توجد نتائج"));
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final cat = list[i];
        final isSelected = _selectedCategoryIds.contains(cat.id);
        return ListTile(
          title: Text(cat.name),
          leading: Icon(
            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
          onTap: () {
            setState(() {
              if (isSelected)
                _selectedCategoryIds.remove(cat.id);
              else
                _selectedCategoryIds.add(cat.id);
            });
            setDialogState(() {});
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            if (readOnly)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.lock, size: 12, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onChanged: onChanged,
          style: TextStyle(color: readOnly ? Colors.grey[700] : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor:
                readOnly
                    ? Colors.grey.shade200
                    : Colors.white, // ✅ تغيير لون الخلفية للمقفل
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
              borderSide: BorderSide(color: color.withOpacity(0.5), width: 2),
            ),
          ),
          validator: (v) => v!.isEmpty && !readOnly ? 'مطلوب' : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'حفظ المنتج',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
