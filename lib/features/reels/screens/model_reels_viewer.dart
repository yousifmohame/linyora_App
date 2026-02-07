import 'package:flutter/material.dart';
import 'package:linyora_project/models/product_model.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:video_player/video_player.dart';
import '../../../models/reel_model.dart';
import '../../reels/services/reels_service.dart';
import '../../public_profiles/services/public_profile_service.dart'; // ✅ إضافة خدمة البروفايل
import '../../public_profiles/screens/model_profile_screen.dart'; // ✅ شاشة البروفايل
import '../../products/screens/product_details_screen.dart'; // ✅ شاشة تفاصيل المنتج
import 'widgets/optimized_video_player.dart';
import 'reels_screen.dart';
import 'widgets/comments_sheet.dart';

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

  final ReelsService _reelsService = ReelsService();
  final PublicProfileService _profileService = PublicProfileService(); // ✅

  late List<ReelModel> _videos;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
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

  // --- دوال التفاعل الكاملة ---

  Future<void> _handleLike(int index) async {
    final reel = _videos[index];
    final bool wasLiked = reel.isLiked;
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
      if (mounted) {
        setState(() {
          reel.isLiked = wasLiked;
          reel.likesCount += wasLiked ? 1 : -1;
        });
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
    } catch (_) {}
  }

  // ✅ 1. دالة المتابعة
  Future<void> _handleFollow(int index) async {
    final reel = _videos[index];
    if (reel.user == null) return;

    final bool wasFollowing = reel.user!.isFollowing;

    // تحديث الحالة لجميع الفيديوهات التابعة لنفس المستخدم
    setState(() {
      for (var v in _videos) {
        if (v.user?.id == reel.user!.id) {
          v.user!.isFollowing = !wasFollowing;
        }
      }
    });

    try {
      await _profileService.toggleFollow(reel.user!.id, !wasFollowing);
    } catch (e) {
      // تراجع عند الخطأ
      if (mounted) {
        setState(() {
          for (var v in _videos) {
            if (v.user?.id == reel.user!.id) {
              v.user!.isFollowing = wasFollowing;
            }
          }
        });
      }
    }
  }

  // ✅ 2. دالة الانتقال للبروفايل
  void _navigateToProfile(int index) {
    final reel = _videos[index];
    if (reel.user == null) return;

    _controllers[index]?.pause(); // إيقاف الفيديو مؤقتاً

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelProfileScreen(modelId: reel.user!.id.toString()),
      ),
    ).then((_) {
      // إعادة التشغيل عند العودة
      if (mounted) _controllers[index]?.play();
    });
  }

  // ✅ 3. دالة عرض المنتجات
  void _showProductsSheet(BuildContext context, List<ProductModel> products) {
    _controllers[_focusedIndex]?.pause(); // إيقاف الفيديو

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder:
                (_, controller) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "المنتجات في هذا الفيديو (${products.length})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          controller: controller,
                          itemCount: products.length,
                          separatorBuilder:
                              (_, __) => const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image:
                                      product.imageUrl.isNotEmpty
                                          ? DecorationImage(
                                            image: NetworkImage(
                                              product.imageUrl,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                          : null,
                                  color: Colors.grey[200],
                                ),
                              ),
                              title: Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  // الانتقال لتفاصيل المنتج
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ProductDetailsScreen(
                                            productId: product.id.toString(),
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(60, 32),
                                ),
                                child: const Text(
                                  "شراء",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    ).then((_) {
      if (mounted) _controllers[_focusedIndex]?.play(); // إعادة التشغيل
    });
  }

  void _showComments(BuildContext context, int index) {
    _controllers[index]?.pause(); // إيقاف الفيديو أثناء التعليق (اختياري)
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
              if (mounted) setState(() => reel.commentsCount++);
            },
          ),
    ).then((_) {
      if (mounted) _controllers[index]?.play();
    });
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
              final isReady =
                  controller != null && controller.value.isInitialized;

              return Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (isReady) {
                        controller.value.isPlaying
                            ? controller.pause()
                            : controller.play();
                      }
                    },
                    child:
                        isReady
                            ? OptimizedVideoPlayer(controller: controller)
                            : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                  ),

                  ReelContentOverlay(
                    reel: _videos[index],
                    // ✅ تم ربط جميع الدوال الآن
                    onLike: () => _handleLike(index),
                    onComment: () => _showComments(context, index),
                    onShare: () => _handleShare(index),
                    onFollow: () => _handleFollow(index), // ✅ ربط المتابعة
                    onProfileTap:
                        () => _navigateToProfile(index), // ✅ ربط البروفايل
                    onShowProducts:
                        (products) => _showProductsSheet(
                          context,
                          products,
                        ), // ✅ ربط المنتجات
                    // ✅ إصلاح حالة التحميل: تظهر العناصر فقط عند جاهزية الفيديو
                    isLoading: !isReady,
                  ),
                ],
              );
            },
          ),

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
