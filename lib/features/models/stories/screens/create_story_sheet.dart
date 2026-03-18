import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import 'package:linyora_project/features/models/stories/services/stories_service.dart';

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

  File? _selectedFile;
  String _storyType = 'image';
  final TextEditingController _textController = TextEditingController();
  String _selectedColor = '#000000';

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

  Future<void> _submit(AppLocalizations l10n) async {
    if ((_storyType == 'image' || _storyType == 'video') &&
        _selectedFile == null) {
      _showError(l10n.pleaseSelectFileMsg); // ✅ مترجم
      return;
    }
    if (_storyType == 'text' && _textController.text.isEmpty) {
      _showError(l10n.pleaseWriteTextMsg); // ✅ مترجم
      return;
    }
    if (_storyType == 'product' && _selectedProductId == null) {
      _showError(l10n.pleaseSelectProductMsg); // ✅ مترجم
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.createStory(
        type: _storyType,
        file: _selectedFile,
        textContent: _textController.text,
        backgroundColor: _selectedColor,
        productId: _selectedProductId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.storyPublishedSuccessMsg), // ✅ مترجم
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError("${l10n.errorPrefix}$e"); // ✅ مترجم
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
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 20),
            ),
            Text(
              l10n.addNewStoryTitle, // ✅ مترجم
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

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
                tabs: [
                  Tab(
                    icon: const Icon(Icons.image, size: 20),
                    text: l10n.imageType,
                  ), // ✅ مترجم
                  Tab(
                    icon: const Icon(Icons.videocam, size: 20),
                    text: l10n.videoType,
                  ), // ✅ مترجم
                  Tab(
                    icon: const Icon(Icons.text_fields, size: 20),
                    text: l10n.textType,
                  ), // ✅ مترجم
                  Tab(
                    icon: const Icon(Icons.shopping_bag, size: 20),
                    text: l10n.productType,
                  ), // ✅ مترجم
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 370,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMediaUploadSection(l10n.imageType, l10n), // ✅ مترجم
                  _buildMediaUploadSection(l10n.videoType, l10n), // ✅ مترجم
                  _buildTextStorySection(l10n), // ✅ تمرير l10n
                  _buildProductSection(l10n), // ✅ تمرير l10n
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isSubmitting ? null : () => _submit(l10n), // ✅ تمرير l10n
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
                label: Text(
                  l10n.publishStoryBtn, // ✅ مترجم
                  style: const TextStyle(
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

  Widget _buildMediaUploadSection(String label, AppLocalizations l10n) {
    return Column(
      children: [
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
                            "${l10n.tapToUploadMsg}$label", // ✅ مترجم
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

        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: l10n.addStoryCaptionHint, // ✅ مترجم
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

  Widget _buildTextStorySection(AppLocalizations l10n) {
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
                decoration: InputDecoration(
                  hintText: l10n.writeYourStoryHereHint, // ✅ مترجم
                  hintStyle: const TextStyle(color: Colors.white70),
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

  Widget _buildProductSection(AppLocalizations l10n) {
    if (_isLoadingProducts)
      return const Center(child: CircularProgressIndicator());

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noProductsToPromoteMsg,
              style: const TextStyle(color: Colors.grey),
            ), // ✅ مترجم
          ],
        ),
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedProductId,
          decoration: InputDecoration(
            labelText: l10n.chooseProductToPromoteLabel, // ✅ مترجم
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
                    product['name'] ?? l10n.defaultProductLabel, // ✅ مترجم
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
                      ? Text(
                        l10n.chooseProductForPreviewMsg,
                        style: const TextStyle(color: Colors.white),
                      ) // ✅ مترجم
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
                              "${_selectedProductData!['price']} ${l10n.currencySAR}", // ✅ عملة مترجمة
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
                              child: Text(
                                l10n.buyNowBtn, // ✅ مترجم (أضفناها في الشاشة السابقة)
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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
        _buildColorPicker(),
      ],
    );
  }

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
