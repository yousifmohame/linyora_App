import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/merchant_story_model.dart';
import '../services/merchant_stories_service.dart';
import 'create_story_modal.dart'; // تأكد من وجود هذا الملف

// الألوان المتاحة للخلفية
const List<Map<String, dynamic>> kStoryColors = [
  {'value': '#000000', 'color': Colors.black, 'label': 'أسود'},
  {'value': '#3B82F6', 'color': Color(0xFF3B82F6), 'label': 'أزرق'},
  {'value': '#10B981', 'color': Color(0xFF10B981), 'label': 'أخضر'},
  {'value': '#8B5CF6', 'color': Color(0xFF8B5CF6), 'label': 'بنفسجي'},
  {'value': '#EF4444', 'color': Color(0xFFEF4444), 'label': 'أحمر'},
  {'value': '#F59E0B', 'color': Color(0xFFF59E0B), 'label': 'ذهبي'},
];

class MerchantStoriesScreen extends StatefulWidget {
  const MerchantStoriesScreen({Key? key}) : super(key: key);

  @override
  State<MerchantStoriesScreen> createState() => _MerchantStoriesScreenState();
}

class _MerchantStoriesScreenState extends State<MerchantStoriesScreen> {
  final MerchantStoriesService _service = MerchantStoriesService();
  List<MerchantStory> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    setState(() => _isLoading = true);
    final stories = await _service.getMyStories();
    if (mounted) {
      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    }
  }

  void _showCreateStoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateStoryModal(),
    ).then((value) {
      if (value == true) {
        _fetchStories();
      }
    });
  }

  // ✅ دالة الحذف مع نافذة تأكيد
  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'حذف القصة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'هل أنت متأكد من حذف هذه القصة؟\nسيتم إزالتها نهائياً ولن يتمكن العملاء من رؤيتها.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // الحذف الفعلي (Optimistic UI Update)
    final previousStories = List<MerchantStory>.from(_stories);
    setState(() {
      _stories.removeWhere((s) => s.id == id);
    });

    try {
      await _service.deleteStory(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف القصة'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      // التراجع في حال الفشل
      setState(() => _stories = previousStories);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل حذف القصة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'قصص المتجر',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStories,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body:
          _isLoading
              ? _buildShimmerGrid()
              : _stories.isEmpty
              ? _buildEmptyState()
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 أعمدة
                    childAspectRatio: 0.6, // نسبة الطول للعرض (شكل ستوري)
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  // +1 من أجل زر الإضافة
                  itemCount: _stories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildAddButton();
                    return _buildStoryCard(_stories[index - 1]);
                  },
                ),
              ),
    );
  }

  // ✅ زر الإضافة بتصميم أنيق
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showCreateStoryModal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'قصة جديدة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ بطاقة القصة (الاحترافية)
  Widget _buildStoryCard(MerchantStory story) {
    return Stack(
      children: [
        // 1. الخلفية (صورة أو لون)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildStoryContent(story),
            ),
          ),
        ),

        // 2. تدرج لوني في الأسفل للنص
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),

        // 3. عداد المشاهدات (أسفل اليسار)
        Positioned(
          bottom: 8,
          left: 8,
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                '${story.views}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 4. أيقونة نوع الوسائط (أسفل اليمين)
        if (story.mediaType != 'text')
          Positioned(
            bottom: 8,
            right: 8,
            child: Icon(
              story.mediaType == 'video' ? Icons.videocam : Icons.image,
              color: Colors.white.withOpacity(0.8),
              size: 14,
            ),
          ),

        // 5. زر الحذف (أعلى اليسار) - ✅ هذا هو الزر المطلوب
        Positioned(
          top: 6,
          left: 6,
          child: GestureDetector(
            onTap: () => _confirmDelete(story.id),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // محتوى القصة الداخلي
  Widget _buildStoryContent(MerchantStory story) {
    if (story.mediaType == 'text') {
      Color bgColor =
          kStoryColors.firstWhere(
            (c) => c['value'] == story.backgroundColor,
            orElse: () => kStoryColors[0],
          )['color'];

      return Container(
        color: bgColor,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Text(
          story.textContent ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else {
      // صورة أو فيديو (صورة مصغرة)
      return CachedNetworkImage(
        imageUrl: story.mediaUrl ?? '',
        fit: BoxFit.cover,
        placeholder: (c, u) => Container(color: Colors.grey[200]),
        errorWidget:
            (c, u, e) =>
                const Center(child: Icon(Icons.error, color: Colors.grey)),
      );
    }
  }

  // حالة التحميل
  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  // حالة الفراغ (لا توجد قصص)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // زر الإضافة الكبير
          _buildAddButton(),
          const SizedBox(height: 24),
          Icon(Icons.auto_stories, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا توجد قصص نشطة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'شارك منتجاتك ولحظاتك مع عملائك الآن',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
