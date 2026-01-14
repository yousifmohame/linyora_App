import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linyora_project/features/supplier/stories/services/stories_service.dart';

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

  // الحالة
  File? _selectedFile;
  String _storyType = 'image';
  final TextEditingController _textController = TextEditingController();
  String _selectedColor = '#000000';
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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // تنظيف عند تغيير التبويب
        _selectedFile = null;
        if (_tabController.index == 0)
          _storyType = 'image';
        else if (_tabController.index == 1)
          _storyType = 'video';
        else
          _storyType = 'text';
      });
    });
  }

  Future<void> _pickMedia() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      // إذا كان فيديو، استخدم pickVideo
    );
    if (_storyType == 'video') {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) setState(() => _selectedFile = File(video.path));
    } else {
      if (file != null) setState(() => _selectedFile = File(file.path));
    }
  }

  Future<void> _submit() async {
    // التحقق
    if ((_storyType == 'image' || _storyType == 'video') &&
        _selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى اختيار ملف")));
      return;
    }
    if (_storyType == 'text' && _textController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى كتابة نص")));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.createStory(
        type: _storyType,
        file: _selectedFile,
        textContent: _textController.text,
        backgroundColor: _selectedColor,
      );
      if (mounted) {
        Navigator.pop(context, true); // إغلاق وإرجاع true للتحديث
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم نشر القصة بنجاح 🎉")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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

          // Tabs Custom
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
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 16),
                      SizedBox(width: 4),
                      Text("صورة"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, size: 16),
                      SizedBox(width: 4),
                      Text("فيديو"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.text_fields, size: 16),
                      SizedBox(width: 4),
                      Text("نص"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Content Area
          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // منع السحب باليد
              children: [
                _buildMediaUpload("صورة"),
                _buildMediaUpload("فيديو"),
                _buildTextEditor(),
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
                      : const Icon(Icons.send),
              label: const Text(
                "نشر القصة",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // لرفع الكيبورد
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildMediaUpload(String label) {
    return InkWell(
      onTap: _pickMedia,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.shade200,
            style: BorderStyle.solid,
          ),
        ),
        child:
            _selectedFile != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedFile!,
                    fit: BoxFit.cover,
                    width: double.infinity,
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
    );
  }

  Widget _buildTextEditor() {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "اكتب شيئاً...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
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
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                          : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
