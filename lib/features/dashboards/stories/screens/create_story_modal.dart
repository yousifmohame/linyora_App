import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:dotted_border/dotted_border.dart'; // إضافة باكيج لحدود منقطة جميلة
import '../services/merchant_stories_service.dart';

// ألوان القصة
const List<Map<String, dynamic>> kStoryColors = [
  {'value': '#000000', 'color': Colors.black, 'label': 'أسود'},
  {'value': '#3B82F6', 'color': Color(0xFF3B82F6), 'label': 'أزرق'},
  {'value': '#10B981', 'color': Color(0xFF10B981), 'label': 'أخضر'},
  {'value': '#8B5CF6', 'color': Color(0xFF8B5CF6), 'label': 'بنفسجي'},
  {'value': '#EF4444', 'color': Color(0xFFEF4444), 'label': 'أحمر'},
  {'value': '#F59E0B', 'color': Color(0xFFF59E0B), 'label': 'ذهبي'},
];

class CreateStoryModal extends StatefulWidget {
  const CreateStoryModal({Key? key}) : super(key: key);

  @override
  State<CreateStoryModal> createState() => _CreateStoryModalState();
}

class _CreateStoryModalState extends State<CreateStoryModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MerchantStoriesService _service = MerchantStoriesService();
  final ImagePicker _picker = ImagePicker();

  String _activeTab = 'image';
  File? _selectedFile;
  VideoPlayerController? _videoController;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _captionController =
      TextEditingController(); // للنص مع الميديا
  String _selectedColor = '#000000';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      switch (_tabController.index) {
        case 0:
          _activeTab = 'image';
          break;
        case 1:
          _activeTab = 'video';
          break;
        case 2:
          _activeTab = 'text';
          break;
      }
      // تنظيف عند الانتقال للنص
      if (_activeTab == 'text') {
        _selectedFile = null;
        _disposeVideoController();
      }
    });
  }

  void _disposeVideoController() {
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _captionController.dispose();
    _disposeVideoController();
    super.dispose();
  }

  Future<void> _pickFile() async {
    XFile? file;
    try {
      if (_activeTab == 'image') {
        file = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
      } else if (_activeTab == 'video') {
        file = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 60),
        );
      }

      if (file != null) {
        setState(() {
          _selectedFile = File(file!.path);
          if (_activeTab == 'video') {
            _disposeVideoController();
            _videoController = VideoPlayerController.file(_selectedFile!)
              ..initialize().then((_) {
                setState(() {}); // تحديث الواجهة عند جاهزية الفيديو
                _videoController!.setLooping(true);
                _videoController!.play();
              });
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل اختيار الملف')));
    }
  }

  Future<void> _submit() async {
    // التحقق من المدخلات
    if ((_activeTab == 'image' || _activeTab == 'video') &&
        _selectedFile == null) {
      _showErrorSnackBar('يرجى اختيار ملف');
      return;
    }
    if (_activeTab == 'text' && _textController.text.trim().isEmpty) {
      _showErrorSnackBar('يرجى كتابة نص للقصة');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // نستخدم النص المناسب حسب النوع
      final textContent =
          _activeTab == 'text'
              ? _textController.text
              : (_captionController.text.isNotEmpty
                  ? _captionController.text
                  : null);

      final success = await _service.createStory(
        type: _activeTab,
        file: _selectedFile,
        textContent: textContent,
        backgroundColor: _selectedColor,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم النشر بنجاح!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('حدث خطأ أثناء النشر: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // نستخدم GestureDetector لإخفاء الكيبورد عند اللمس في أي مكان
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92, // ارتفاع مريح
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics:
                    const NeverScrollableScrollPhysics(), // نمنع السحب باليد لضمان استقرار التجربة
                children: [
                  _buildMediaTab(isImage: true),
                  _buildMediaTab(isImage: false),
                  _buildTextTab(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'قصة جديدة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'شارك لحظاتك المميزة',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: const Color(0xFFF43F5E),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ), // تأكد من نوع الخط
        tabs: const [
          Tab(text: 'صورة', icon: Icon(Icons.image_outlined, size: 18)),
          Tab(text: 'فيديو', icon: Icon(Icons.videocam_outlined, size: 18)),
          Tab(text: 'نص', icon: Icon(Icons.text_fields, size: 18)),
        ],
      ),
    );
  }

  Widget _buildMediaTab({required bool isImage}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Upload Area with Dotted Border
          GestureDetector(
            onTap: _pickFile,
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                color:
                    _selectedFile != null
                        ? Colors.transparent
                        : Colors.pink.shade200,
                strokeWidth: 2,
                dashPattern: const [8, 4],

                radius: const Radius.circular(24),
              ),

              child: Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      _selectedFile != null
                          ? Colors.black
                          : Colors.pink.shade50.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child:
                    _selectedFile != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child:
                              isImage
                                  ? Image.file(
                                    _selectedFile!,
                                    fit: BoxFit.cover,
                                  )
                                  : (_videoController != null &&
                                      _videoController!.value.isInitialized)
                                  ? AspectRatio(
                                    aspectRatio:
                                        _videoController!.value.aspectRatio,
                                    child: VideoPlayer(_videoController!),
                                  )
                                  : const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isImage
                                    ? Icons.add_photo_alternate_rounded
                                    : Icons.video_call_rounded,
                                size: 40,
                                color: const Color(0xFFF43F5E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isImage
                                  ? 'اضغط لاختيار صورة'
                                  : 'اضغط لاختيار فيديو',
                              style: const TextStyle(
                                color: Color(0xFFF43F5E),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'يدعم PNG, JPG, MP4',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Caption Field
          TextField(
            controller: _captionController,
            decoration: InputDecoration(
              hintText: 'أضف تعليقاً توضيحياً (اختياري)...',
              prefixIcon: const Icon(Icons.edit_note, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
            minLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'محتوى النص',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'اكتب قصتك هنا...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 4,
            style: const TextStyle(fontSize: 16),
            onChanged: (_) => setState(() {}), // تحديث المعاينة فوراً
          ),

          const SizedBox(height: 24),
          const Text(
            'لون الخلفية',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                kStoryColors.map((color) {
                  final isSelected = _selectedColor == color['value'];
                  return GestureDetector(
                    onTap:
                        () => setState(() => _selectedColor = color['value']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color['color'],
                        shape: BoxShape.circle,
                        border:
                            isSelected
                                ? Border.all(color: Colors.blue, width: 3)
                                : Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: (color['color'] as Color).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child:
                          isSelected
                              ? const Center(
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 32),

          const Text(
            'معاينة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  kStoryColors.firstWhere(
                    (c) => c['value'] == _selectedColor,
                    orElse: () => kStoryColors[0],
                  )['color'],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Text(
              _textController.text.isEmpty
                  ? 'سيظهر نصك هنا...'
                  : _textController.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: const Color(0xFFF43F5E).withOpacity(0.4),
            ),
            child:
                _isSubmitting
                    ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'نشر القصة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
