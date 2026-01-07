import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:video_player/video_player.dart';
import '../../../models/reel_model.dart';
import '../../reels/services/reels_service.dart'; // 1. استيراد الخدمة
import 'widgets/optimized_video_player.dart';
import 'reels_screen.dart'; // لاستيراد ReelContentOverlay
import 'widgets/comments_sheet.dart'; // لاستيراد CommentsSheet

class ModelReelsViewer extends StatefulWidget {
  final List<ReelModel> reels;
  final int initialIndex;

  const ModelReelsViewer({
    Key? key,
    required this.reels,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<ModelReelsViewer> createState() => _ModelReelsViewerState();
}

class _ModelReelsViewerState extends State<ModelReelsViewer> {
  late PreloadPageController _pageController;
  final Map<int, VideoPlayerController> _controllers = {};

  // 2. تعريف الخدمة
  final ReelsService _reelsService = ReelsService();

  // نسخة محلية من القائمة لتحديث الحالة
  late List<ReelModel> _videos;

  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    // نسخ القائمة القادمة من الـ Widget للتحكم فيها محلياً
    _videos = List.from(widget.reels);

    _focusedIndex = widget.initialIndex;
    _pageController = PreloadPageController(initialPage: widget.initialIndex);
    _initController(_focusedIndex);
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    _pageController.dispose();
    super.dispose();
  }

  // --- دوال التحكم بالفيديو ---

  Future<void> _initController(int index) async {
    if (_controllers.containsKey(index) || index < 0 || index >= _videos.length)
      return;

    final reel = _videos[index];
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(reel.videoUrl),
    );

    await controller.initialize();
    await controller.setLooping(true);

    if (mounted) {
      setState(() {
        _controllers[index] = controller;
      });
      if (index == _focusedIndex) controller.play();
    }
  }

  void _onPageChanged(int index) {
    _controllers[_focusedIndex]?.pause();
    setState(() => _focusedIndex = index);

    if (!_controllers.containsKey(index)) {
      _initController(index);
    } else {
      _controllers[index]?.play();
    }

    _initController(index + 1);
  }

  // --- دوال التفاعل ---

  Future<void> _handleLike(int index) async {
    final reel = _videos[index];
    final bool wasLiked = reel.isLiked;

    // تحديث الواجهة فوراً (Optimistic Update)
    setState(() {
      reel.isLiked = !wasLiked;
      reel.likesCount += wasLiked ? -1 : 1;
    });

    try {
      if (wasLiked) {
        await _reelsService.removeLike(reel.id.toString());
      } else {
        await _reelsService.toggleLike(reel.id.toString());
      }
    } catch (e) {
      // تراجع في حالة الخطأ
      if (mounted) {
        setState(() {
          reel.isLiked = wasLiked;
          reel.likesCount += wasLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ في الاتصال')));
      }
    }
  }

  Future<void> _handleShare(int index) async {
    final reel = _videos[index];
    try {
      await _reelsService.trackShare(reel.id.toString());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت المشاركة بنجاح!')));
      }
    } catch (e) {
      // تجاهل الخطأ البسيط في التتبع
    }
  }

  void _showComments(BuildContext context, int index) {
    final reel = _videos[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CommentsSheet(
            reelId: reel.id.toString(),
            service: _reelsService,
            onCommentAdded: () {
              if (mounted) {
                setState(() {
                  reel.commentsCount++;
                });
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PreloadPageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final controller = _controllers[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // طبقة الفيديو
                  GestureDetector(
                    onTap: () {
                      if (controller != null && controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller?.play();
                      }
                    },
                    child:
                        controller != null && controller.value.isInitialized
                            ? OptimizedVideoPlayer(controller: controller)
                            : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                  ),

                  // طبقة التفاعل (ReelContentOverlay)
                  ReelContentOverlay(
                    reel: _videos[index],
                    // تمرير الدوال هنا
                    onLike: () => _handleLike(index),
                    onComment: () => _showComments(context, index),
                    onShare: () => _handleShare(index), onFollow: () {  }, onProfileTap: () {  },
                  ),
                ],
              );
            },
          ),

          // زر العودة
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black26,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
