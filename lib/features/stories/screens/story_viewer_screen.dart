import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/story_model.dart';
import '../services/stories_service.dart';
import '../../products/screens/product_details_screen.dart';

class StoryViewerScreen extends StatefulWidget {
  final int feedId;
  final String title;
  final String imageUrl;
  final bool isSection;

  const StoryViewerScreen({
    super.key,
    required this.feedId,
    required this.title,
    required this.imageUrl,
    required this.isSection,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final StoryController controller = StoryController();
  final StoriesService _storiesService = StoriesService();

  List<StoryModel>? _stories;
  List<StoryItem>? _storyItems;
  bool _hasError = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  // ✅ التعديل 1: تحسين دالة التخلص من الموارد
  @override
  void dispose() {
    // إيقاف التشغيل فوراً لمنع استمراره في الخلفية
    controller.pause();
    controller.dispose();
    super.dispose();
  }

  // ✅ التعديل 2: دالة موحدة للخروج الآمن
  void _onClose() {
    controller.pause(); // إيقاف الفيديو/القصة
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _loadStories() async {
    // ... (نفس الكود السابق)
    try {
      final stories = await _storiesService.getStoriesById(
        widget.feedId,
        widget.isSection,
      );
      if (mounted) {
        setState(() {
          if (stories.isNotEmpty) {
            _stories = stories;
            _storyItems = _buildStoryItems(stories);
          } else {
            _hasError = true;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Color _parseColor(String? hexColor) {
    // ... (نفس الكود السابق)
    if (hexColor == null || hexColor.isEmpty) return Colors.black;
    try {
      hexColor = hexColor.replaceAll("#", "");
      if (hexColor.length == 6) hexColor = "FF$hexColor";
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }

  Widget _mirrorContentIfRtl(Widget child) {
    // ... (نفس الكود السابق)
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    if (!isRtl) return child;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: child,
    );
  }

  List<StoryItem> _buildStoryItems(List<StoryModel> stories) {
    // ... (نفس الكود السابق)
    return stories.map((story) {
      final String? imageToDisplay = story.mediaUrl ?? story.productImage;

      if (story.mediaType == MediaType.text && imageToDisplay == null) {
        return StoryItem(
          _mirrorContentIfRtl(
            Container(
              color: _parseColor(story.backgroundColor),
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Text(
                  story.textContent ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          shown: story.isViewed,
          duration: const Duration(seconds: 5),
        );
      } else if (story.mediaType == MediaType.video && story.mediaUrl != null) {
        return StoryItem.pageVideo(
          story.mediaUrl!,
          controller: controller,
          caption:
              story.textContent != null
                  ? _mirrorContentIfRtl(
                    Text(
                      story.textContent!,
                      style: const TextStyle(
                        color: Colors.white,
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  )
                  : null,
          shown: story.isViewed,
          // ⚠️ ملاحظة: تأكد أنك تستخدم النسخة الحديثة من المكتبة التي تدعم التحكم
        );
      } else if (imageToDisplay != null) {
        return StoryItem(
          _mirrorContentIfRtl(
            Stack(
              children: [
                Container(color: _parseColor(story.backgroundColor)),
                CachedNetworkImage(
                  imageUrl: imageToDisplay,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder:
                      (c, u) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                  errorWidget:
                      (c, u, e) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                ),
                if (story.textContent != null &&
                    story.textContent!.trim().isNotEmpty)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        story.textContent!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          shown: story.isViewed,
          duration: const Duration(seconds: 5),
        );
      }
      return StoryItem.text(title: "", backgroundColor: Colors.black);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 40),
              const SizedBox(height: 16),
              const Text("لا توجد قصص", style: TextStyle(color: Colors.white)),
              TextButton(
                onPressed: _onClose, // ✅ استخدام دالة الإغلاق الآمن
                child: const Text("رجوع", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
      );
    }

    if (_stories == null || _storyItems == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          // ✅ استخدام دالة الإغلاق الآمن عند السحب
          if (details.primaryDelta! > 10) _onClose();
        },
        child: Stack(
          children: [
            Transform(
              alignment: Alignment.center,
              transform:
                  isRtl ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: StoryView(
                  storyItems: _storyItems!,
                  controller: controller,
                  repeat: false,
                  progressPosition: ProgressPosition.top,
                  inline: false,
                  onStoryShow: (storyItem, index) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _currentIndex = index);
                    });

                    if (!_stories![index].isViewed) {
                      _storiesService.markAsViewed(_stories![index].id);
                      _stories![index].isViewed = true;
                    }
                  },
                  onComplete: _onClose, // ✅ استخدام دالة الإغلاق الآمن
                  onVerticalSwipeComplete: (direction) {
                    if (direction == Direction.down)
                      _onClose(); // ✅ استخدام دالة الإغلاق الآمن
                  },
                ),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 90,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        placeholder:
                            (context, url) =>
                                Container(color: Colors.grey[800]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _onClose, // ✅ استخدام دالة الإغلاق الآمن
                  ),
                ],
              ),
            ),

            if (_stories!.isNotEmpty &&
                _stories![_currentIndex].productId != null)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      controller.pause();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ProductDetailsScreen(
                                productId:
                                    _stories![_currentIndex].productId
                                        .toString(),
                              ),
                        ),
                      ).then((_) => controller.play());
                    },
                    child: Container(
                      // ... (نفس تصميم الزر)
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 20,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _stories![_currentIndex].productName ??
                                  "عرض المنتج",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_stories![_currentIndex].productPrice !=
                              null) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 16,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${_stories![_currentIndex].productPrice!.toInt()} ر.س",
                              style: const TextStyle(
                                color: Color(0xFF00C853),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_up,
                            size: 20,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
