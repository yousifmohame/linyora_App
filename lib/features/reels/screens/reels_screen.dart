import 'dart:io';
import 'package:flutter/material.dart';
import 'package:linyora_project/features/reels/screens/widgets/comments_sheet.dart';
import 'package:linyora_project/models/reel_model.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

// تأكد من المسارات الصحيحة
import '../../../../core/utils/video_cache_manager.dart';
import '../services/reels_service.dart';
import 'widgets/optimized_video_player.dart';

class ReelsScreen extends StatefulWidget {
  final bool isActive;

  const ReelsScreen({Key? key, required this.isActive}) : super(key: key);

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  final ReelsService _reelsService = ReelsService();
  List<ReelModel> _videos = [];
  bool _isLoading = true;

  final PreloadPageController _pageController = PreloadPageController();
  final Map<int, VideoPlayerController> _controllers = {};
  int _focusedIndex = 0;
  bool _isAppActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReels();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeAllControllers();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasActive = _isAppActive;
    _isAppActive = state == AppLifecycleState.resumed;

    if (!_isAppActive) {
      _pauseAll();
    } else if (_isAppActive && !wasActive && widget.isActive) {
      _playController(_focusedIndex);
    }
  }

  @override
  void didUpdateWidget(ReelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _playController(_focusedIndex);
      } else {
        _pauseAll();
      }
    }
  }

  Future<void> _loadReels() async {
    try {
      final reels = await _reelsService.getStyleTodayReels();
      if (mounted) {
        setState(() {
          _videos = reels;
          _isLoading = false;
        });
        if (reels.isNotEmpty) {
          await _initController(0);
          if (widget.isActive) _playController(0);
          if (reels.length > 1) _initController(1);
        }
      }
    } catch (e) {
      debugPrint("Error loading reels: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onPageChanged(int index) async {
    // إيقاف جميع الفيديوهات الأخرى
    _controllers.forEach((key, controller) {
      if (key != index && controller.value.isPlaying) {
        controller.pause();
      }
    });

    setState(() {
      _focusedIndex = index;
    });

    final prevIndex = (index - 1).clamp(0, _videos.length - 1);
    final nextIndex = (index + 1).clamp(0, _videos.length - 1);

    // تنظيف الذاكرة
    _controllers.keys
        .where((k) => k != index && k != prevIndex && k != nextIndex)
        .toList()
        .forEach((k) {
          _controllers[k]?.dispose();
          _controllers.remove(k);
        });

    if (!_controllers.containsKey(index)) {
      await _initController(index);
    }

    if (widget.isActive && _isAppActive) {
      _playController(index);
    }

    _initController(nextIndex);
    if (index > 0) _initController(prevIndex);
  }

  Future<void> _initController(int index) async {
    if (_controllers.containsKey(index) || index >= _videos.length || index < 0)
      return;

    try {
      final reel = _videos[index];
      final file = await VideoCacheUtils.getCachedVideoFile(reel.videoUrl);

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);

      if (mounted) {
        setState(() {
          _controllers[index] = controller;
        });
      }
    } catch (e) {
      debugPrint("Error initializing video $index: $e");
    }
  }

  // 1. دالة الإعجاب
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
        // إذا كان معجب سابقاً، نحذف الإعجاب
        await _reelsService.removeLike(reel.id.toString());
      } else {
        // إذا لم يكن معجب، نضيف إعجاب
        await _reelsService.toggleLike(reel.id.toString());
      }
    } catch (e) {
      // تراجع في حالة الخطأ
      setState(() {
        reel.isLiked = wasLiked;
        reel.likesCount += wasLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ في الاتصال')));
    }
  }

  // 2. دالة المشاركة
  Future<void> _handleShare(int index) async {
    final reel = _videos[index];

    // التغيير هنا: إضافة .toString()
    await _reelsService.trackShare(reel.id.toString());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت المشاركة بنجاح!')));
  }

  // 3. دالة عرض التعليقات (Bottom Sheet)
  void _showComments(BuildContext context, int index) {
    final reel = _videos[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CommentsSheet(
            // التغيير هنا: إضافة .toString()
            reelId: reel.id.toString(),
            service: _reelsService,
            onCommentAdded: () {
              setState(() {
                reel.commentsCount++;
              });
            },
          ),
    );
  }

  void _playController(int index) {
    final controller = _controllers[index];
    if (controller != null && controller.value.isInitialized) {
      controller.play();
      setState(() {}); // تحديث الواجهة لإخفاء أيقونة التشغيل
    }
  }

  // دالة لتبديل حالة التشغيل عند الضغط
  void _togglePlayPause() {
    final controller = _controllers[_focusedIndex];
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
      setState(() {}); // تحديث الواجهة لإظهار/إخفاء أيقونة التشغيل
    }
  }

  void _pauseAll() {
    _controllers.values.forEach((c) {
      if (c.value.isPlaying) c.pause();
    });
  }

  void _disposeAllControllers() {
    _controllers.values.forEach((c) => c.dispose());
    _controllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "لا توجد فيديوهات متاحة",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PreloadPageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        preloadPagesCount: 1,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final controller = _controllers[index];
          final isPlaying = controller?.value.isPlaying ?? false;
          final isInitialized = controller?.value.isInitialized ?? false;

          return Stack(
            fit: StackFit.expand,
            children: [
              // الطبقة 1: الفيديو
              OptimizedVideoPlayer(controller: controller),

              // الطبقة 2: منطقة اللمس (تغطي الشاشة بالكامل)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    color: Colors.transparent, // ضروري لاستقبال اللمسات
                  ),
                ),
              ),

              // الطبقة 3: أيقونة التشغيل (تظهر في المنتصف عند التوقف)
              if (isInitialized && !isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 80,
                    color: Colors.white60,
                  ),
                ),

              // الطبقة 4: التدرج اللوني (IgnorePointer ليمر اللمس من خلاله)
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black54,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: [0.0, 0.2, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // الطبقة 5: البيانات والأزرار (تستقبل اللمس الخاص بها)
              ReelContentOverlay(
                reel: _videos[index],
                onLike: () => _handleLike(index),
                onComment: () => _showComments(context, index),
                onShare: () => _handleShare(index),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- ويدجت عرض البيانات (Overlay) ---
class ReelContentOverlay extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const ReelContentOverlay({
    Key? key,
    required this.reel,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      left: 10,
      right: 10,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // معلومات المستخدم (يسار)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[800],
                      backgroundImage:
                          (reel.user?.avatar != null &&
                                  reel.user!.avatar.isNotEmpty)
                              ? CachedNetworkImageProvider(reel.user!.avatar)
                              : null,
                      child:
                          (reel.user?.avatar == null ||
                                  reel.user!.avatar.isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reel.user?.name ?? 'مستخدم Linyora',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (reel.description != null)
                  Text(
                    reel.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                if (reel.products != null && reel.products!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: GestureDetector(
                      onTap: () {
                        // إضافة كود فتح المنتجات هنا
                        print("Open products");
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${reel.products!.length} منتجات',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // أزرار التفاعل (يمين)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon:
                    reel.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border, // تغيير الأيقونة
                label: '${reel.likesCount}',
                color: reel.isLiked ? Colors.red : Colors.white, // تغيير اللون
                onTap: onLike, // ربط الدالة
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.comment,
                label: '${reel.commentsCount}',
                onTap: onComment, // ربط الدالة
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.share,
                label: 'مشاركة',
                onTap: onShare, // ربط الدالة
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
