import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/models/stories/services/stories_service.dart'; // تأكد من إضافتها

class CreateStorySheet extends StatefulWidget {
  const CreateStorySheet({Key? key}) : super(key: key);

  @override
  State<CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends State<CreateStorySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StoriesService _service = StoriesService();
  final ImagePicker _picker = ImagePicker();

  // State
  File? _selectedFile;
  String _storyType = 'image';
  final TextEditingController _textController = TextEditingController();
  String _selectedColor = '#000000'; // Default black

  // Products Logic
  List<Map<String, dynamic>> _products = [];
  String? _selectedProductId;
  Map<String, dynamic>? _selectedProductData;
  bool _isLoadingProducts = false;

  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _colors = [
    {'hex': '#000000', 'color': Colors.black},
    {'hex': '#3B82F6', 'color': const Color(0xFF3B82F6)},
    {'hex': '#10B981', 'color': const Color(0xFF10B981)},
    {'hex': '#8B5CF6', 'color': const Color(0xFF8B5CF6)},
    {'hex': '#EF4444', 'color': const Color(0xFFEF4444)},
    {'hex': '#F59E0B', 'color': const Color(0xFFF59E0B)},
  ];

  @override
  void initState() {
    super.initState();
    // ✅ 4 تبويبات الآن: صورة، فيديو، نص، منتج
    _tabController = TabController(length: 4, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFile = null;
          _selectedProductId = null;
          _selectedProductData = null;

          switch (_tabController.index) {
            case 0:
              _storyType = 'image';
              break;
            case 1:
              _storyType = 'video';
              break;
            case 2:
              _storyType = 'text';
              break;
            case 3:
              _storyType = 'product';
              _fetchProducts();
              break;
          }
        });
      }
    });
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _service.getPromotableProducts();
      if (mounted) setState(() => _products = products);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _pickMedia() async {
    final XFile? file;
    if (_storyType == 'video') {
      file = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      file = await _picker.pickImage(source: ImageSource.gallery);
    }

    if (file != null) {
      setState(() => _selectedFile = File(file!.path));
    }
  }

  Future<void> _submit() async {
    // Validation
    if ((_storyType == 'image' || _storyType == 'video') &&
        _selectedFile == null) {
      _showError("يرجى اختيار ملف");
      return;
    }
    if (_storyType == 'text' && _textController.text.isEmpty) {
      _showError("يرجى كتابة نص");
      return;
    }
    if (_storyType == 'product' && _selectedProductId == null) {
      _showError("يرجى اختيار منتج");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.createStory(
        type: _storyType,
        file: _selectedFile,
        textContent:
            _textController.text, // ✅ يتم إرسال النص مع الصورة/الفيديو أيضاً
        backgroundColor: _selectedColor,
        productId: _selectedProductId, // ✅ إرسال المنتج
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم نشر القصة بنجاح 🎉"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError("خطأ: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 20),
            ),
            const Text(
              "إضافة قصة جديدة",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                labelColor: Colors.blue[800],
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.image, size: 20), text: "صورة"),
                  Tab(icon: Icon(Icons.videocam, size: 20), text: "فيديو"),
                  Tab(icon: Icon(Icons.text_fields, size: 20), text: "نص"),
                  Tab(
                    icon: Icon(Icons.shopping_bag, size: 20),
                    text: "منتج",
                  ), // ✅ التبويب الجديد
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content Body
            SizedBox(
              height: 370, // زيادة الارتفاع لاستيعاب المحتوى
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMediaUploadSection("صورة"),
                  _buildMediaUploadSection("فيديو"),
                  _buildTextStorySection(),
                  _buildProductSection(), // ✅ واجهة المنتجات
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF105C6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon:
                    _isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  "نشر القصة",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 1. قسم رفع الصور/الفيديو (مع دعم النص)
  Widget _buildMediaUploadSection(String label) {
    return Column(
      children: [
        // مساحة الرفع
        Expanded(
          child: InkWell(
            onTap: _pickMedia,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child:
                  _selectedFile != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_selectedFile!, fit: BoxFit.cover),
                            // زر تغيير الصورة
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _pickMedia,
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              _storyType == 'video'
                                  ? Icons.video_library
                                  : Icons.add_photo_alternate,
                              size: 32,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "اضغط لرفع $label",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ✅ حقل النص المضاف للصورة/الفيديو
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: "أضف شرحاً للقصة (اختياري)...",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.short_text, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // ✅ 2. قسم النص فقط (مع ألوان الخلفية)
  Widget _buildTextStorySection() {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: TextField(
                controller: _textController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "اكتب قصتك هنا...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildColorPicker(),
      ],
    );
  }

  // ✅ 3. قسم المنتجات (الجديد)
  Widget _buildProductSection() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              "لا توجد منتجات متاحة للترويج",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // القائمة المنسدلة لاختيار المنتج
        DropdownButtonFormField<String>(
          value: _selectedProductId,
          decoration: InputDecoration(
            labelText: "اختر منتجاً للترويج",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          items:
              _products.map((product) {
                return DropdownMenuItem(
                  value: product['id'].toString(),
                  child: Text(
                    product['name'] ?? 'منتج',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedProductId = val;
              _selectedProductData = _products.firstWhere(
                (p) => p['id'].toString() == val,
              );
            });
          },
        ),

        const SizedBox(height: 16),

        // معاينة كرت المنتج (Product Card Preview)
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child:
                  _selectedProductData == null
                      ? const Text(
                        "اختر منتجاً للمعانية",
                        style: TextStyle(color: Colors.white),
                      )
                      : Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl:
                                    _selectedProductData!['image_url'] ?? '',
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget:
                                    (_, __, ___) => Container(
                                      height: 120,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedProductData!['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "${_selectedProductData!['price']} ر.س",
                              style: const TextStyle(
                                color: Color(0xFFF105C6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "اشترِ الآن",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
        ),

        const SizedBox(height: 12),
        // Color Picker for Product Background
        _buildColorPicker(),
      ],
    );
  }

  // ويدجت اختيار الألوان (مشترك)
  Widget _buildColorPicker() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final colorData = _colors[index];
          bool isSelected = _selectedColor == colorData['hex'];
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = colorData['hex']),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorData['color'],
                shape: BoxShape.circle,
                border:
                    isSelected
                        ? Border.all(color: Colors.blue, width: 3)
                        : null,
              ),
              child:
                  isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
            ),
          );
        },
      ),
    );
  }
}
