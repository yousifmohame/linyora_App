import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

// --- استيرادات مشروعك ---
import 'package:linyora_project/core/utils/event_bus.dart';
import 'package:linyora_project/features/public_profiles/screens/model_profile_screen.dart';
import 'package:linyora_project/features/public_profiles/services/public_profile_service.dart';
import 'package:linyora_project/features/reels/screens/widgets/comments_sheet.dart';
import 'package:linyora_project/models/reel_model.dart';
// import '../../../../core/utils/video_cache_manager.dart'; // ❌ لم نعد بحاجة لهذا لغرض التشغيل الفوري
import '../services/reels_service.dart';

class ReelsScreen extends StatefulWidget {
  final bool isActive;
  const ReelsScreen({Key? key, required this.isActive}) : super(key: key);

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  // Services
  final ReelsService _reelsService = ReelsService();
  final PublicProfileService _profileService = PublicProfileService();

  // Controllers
  final PreloadPageController _pageController = PreloadPageController();
  final Map<int, ChewieController> _controllers = {};

  // State Variables
  List<ReelModel> _videos = [];
  bool _isLoading = true;
  bool _isAppActive = true;
  int _focusedIndex = 0;
  bool _isProcessingFollow = false;

  // التحكم في التفاعل
  bool _interactionUnlocked = false;
  bool _isAudioFadedIn = false;

  // أدوات التحكم
  Timer? _scrollDebounceTimer;
  ScrollPhysics _scrollPhysics = const NeverScrollableScrollPhysics();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReels();
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _muteAndPauseAll(); // كتم الصوت قبل التخلص
    _disposeAllControllers();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    _isAppActive = active;

    if (!active) {
      _muteAndPauseAll();
    } else if (widget.isActive) {
      _forcePlayAtIndex(_focusedIndex);
    }
  }

  @override
  void didUpdateWidget(ReelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _forcePlayAtIndex(_focusedIndex);
      } else {
        _muteAndPauseAll();
      }
    }
  }

  Future<void> _loadReels() async {
    try {
      final reels = await _reelsService.getStyleTodayReels();
      if (!mounted) return;

      setState(() {
        _videos = reels;
        _isLoading = false;
      });

      if (reels.isNotEmpty) {
        await _initAndPlay(0);
        if (reels.length > 1) _preload(1);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPageChanged(int index) {
    // 1. كتم وإيقاف فوري للجميع
    _muteAndPauseAll();
    _scrollDebounceTimer?.cancel();

    setState(() {
      _focusedIndex = index;
      _interactionUnlocked = false;
      // قفل التمرير حتى يعمل الفيديو الجديد (لمنع السكرول المجنون)
      _scrollPhysics = const NeverScrollableScrollPhysics();
    });

    _collectGarbage(index);

    // مهلة قصيرة جداً (50ms) لبدء التحميل
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 50), () async {
      if (!mounted || !_isAppActive || !widget.isActive) return;

      await _initAndPlay(index);

      // تحميل الفيديو التالي في الخلفية (Buffering)
      final next = index + 1;
      if (next < _videos.length) _preload(next);
    });
  }

  // --- دوال التحكم في الفيديو والصوت (محسنة) ---

  // دالة آمنة للإيقاف وكتم الصوت
  void _muteAndPauseAll() {
    for (final c in _controllers.values) {
      final videoCtrl = c.videoPlayerController;
      if (videoCtrl.value.volume > 0) {
        videoCtrl.setVolume(0.0); // كتم الصوت فوراً
      }
      if (videoCtrl.value.isPlaying) {
        c.pause();
        videoCtrl.pause();
      }
    }
  }

  // رفع الصوت تدريجياً (Fade In) لمنع "الفرقعة" الصوتية
  void _fadeInVolume(VideoPlayerController controller) async {
    if (!mounted) return;
    double volume = 0.0;
    // خطوات سريعة للوصول لـ 1.0
    while (volume < 1.0) {
      if (!controller.value.isPlaying) return; // توقف إذا توقف الفيديو
      volume += 0.1;
      await controller.setVolume(volume.clamp(0.0, 1.0));
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _forcePlayAtIndex(int index) {
    if (!widget.isActive) return;

    final c = _controllers[index];
    // تحقق صارم
    if (c == null ||
        !c.videoPlayerController.value.isInitialized ||
        index != _focusedIndex) {
      return;
    }

    final videoCtrl = c.videoPlayerController;

    // 1. ابدأ بصوت مكتوم تماماً
    videoCtrl.setVolume(0.0);

    // 2. تشغيل الفيديو
    c.play();

    _isAudioFadedIn = false;
    _interactionUnlocked = false;

    // 3. مراقب لفتح الصوت والتفاعل
    void listener() {
      final value = videoCtrl.value;

      // نعتبر الفيديو "يعمل" إذا تحرك المؤشر قليلاً (مثلاً 100ms)
      // هذا يضمن أن الإطارات بدأت بالتحرك فعلياً
      if (value.isPlaying &&
          value.position > const Duration(milliseconds: 100)) {
        videoCtrl.removeListener(listener);

        if (!mounted || index != _focusedIndex) {
          videoCtrl.setVolume(0.0);
          c.pause();
          return;
        }

        // فتح التفاعل والسكرول
        setState(() {
          _interactionUnlocked = true;
          _scrollPhysics = const AlwaysScrollableScrollPhysics();
        });

        // الآن فقط نرفع الصوت
        if (!_isAudioFadedIn) {
          _isAudioFadedIn = true;
          _fadeInVolume(videoCtrl);
        }
      }
    }

    videoCtrl.addListener(listener);
  }

  Future<void> _initAndPlay(int index) async {
    if (index < 0 || index >= _videos.length) return;

    if (_controllers.containsKey(index)) {
      _forcePlayAtIndex(index);
      return;
    }

    try {
      final reel = _videos[index];

      // ✅ التغيير الجوهري: استخدام networkUrl بدلاً من file
      // هذا يسمح بالتشغيل أثناء التحميل (Buffering) مثل تيك توك ويوتيوب
      final videoCtrl = VideoPlayerController.networkUrl(
        Uri.parse(reel.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
        ), // خيار لتحسين الصوت
      );

      // تهيئة (تأخذ وقت أقل بكثير الآن لأنها لا تنتظر الملف كاملاً)
      await videoCtrl.initialize();

      if (!mounted || index != _focusedIndex) {
        await videoCtrl.setVolume(0);
        await videoCtrl.dispose();
        return;
      }

      final chewie = ChewieController(
        videoPlayerController: videoCtrl,
        looping: true,
        autoPlay: false,
        showControls: false,
        allowFullScreen: false,
        aspectRatio: videoCtrl.value.aspectRatio,
        // لون خلفية أسود أثناء التحميل
        placeholder: Container(color: Colors.black),
      );

      setState(() => _controllers[index] = chewie);

      _forcePlayAtIndex(index);
    } catch (e) {
      debugPrint("Error video $index: $e");
      // في حالة الخطأ، نفتح السكرول لكي لا يعلق المستخدم
      if (mounted)
        setState(() => _scrollPhysics = const AlwaysScrollableScrollPhysics());
    }
  }

  Future<void> _preload(int index) async {
    if (_controllers.containsKey(index) || index >= _videos.length) return;
    try {
      // البريلود أيضاً يستخدم NetworkUrl
      final videoCtrl = VideoPlayerController.networkUrl(
        Uri.parse(_videos[index].videoUrl),
      );
      await videoCtrl.initialize();

      final chewie = ChewieController(
        videoPlayerController: videoCtrl,
        looping: true,
        autoPlay: false,
        showControls: false,
        aspectRatio: videoCtrl.value.aspectRatio,
      );

      if (mounted) setState(() => _controllers[index] = chewie);
    } catch (_) {}
  }

  void _collectGarbage(int index) {
    final allowed = {index, index - 1, index + 1};
    _controllers.keys.where((k) => !allowed.contains(k)).toList().forEach((k) {
      _controllers[k]?.videoPlayerController.setVolume(0); // أمان إضافي
      _controllers[k]?.pause();
      _controllers[k]?.dispose();
      _controllers.remove(k);
    });
  }

  void _disposeAllControllers() {
    for (final c in _controllers.values) {
      c.videoPlayerController.setVolume(0);
      c.pause();
      c.dispose();
    }
    _controllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: ReelSkeleton()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PreloadPageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: _scrollPhysics,
        itemCount: _videos.length,
        preloadPagesCount: 0,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final controller = _controllers[index];
          final isInitialized =
              controller != null &&
              controller.videoPlayerController.value.isInitialized;

          final isBuffering =
              isInitialized &&
              controller.videoPlayerController.value.isBuffering;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. الفيديو
              if (isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.videoPlayerController.value.size.width,
                    height: controller.videoPlayerController.value.size.height,
                    child: Chewie(
                      key: ValueKey(controller),
                      controller: controller,
                    ),
                  ),
                )
              else
                const ReelSkeleton(),

              // 2. مؤشر التحميل (Buffering)
              if (isBuffering)
                const Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),

              // 3. طبقة اللمس
              if (isInitialized && _interactionUnlocked)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (controller.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                      setState(() {});
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),

              // 4. أيقونة التشغيل
              if (isInitialized &&
                  _interactionUnlocked &&
                  !controller.isPlaying &&
                  !isBuffering)
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 80,
                    color: Colors.white60,
                  ),
                ),

              // 5. تدرج الظل
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

              // 6. المحتوى (Overlay) - ✅ تمت إزالة AbsorbPointer من هنا
              ReelContentOverlay(
                reel: _videos[index],
                isLoading: !isInitialized, // تمرير الحالة للداخل
                onLike: () => _handleLike(index),
                onComment: () => _showComments(context, index),
                onShare: () => _handleShare(index),
                onFollow: () => _handleFollow(index),
                onProfileTap: () {
                  _muteAndPauseAll();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ModelProfileScreen(
                            modelId: _videos[index].user!.id.toString(),
                          ),
                    ),
                  ).then((_) {
                    if (widget.isActive) _forcePlayAtIndex(index);
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // --- بقية دوال الـ Actions (Like, Share, etc) كما هي ---
  Future<void> _handleLike(int index) async {
    final reel = _videos[index];
    final bool wasLiked = reel.isLiked;
    setState(() {
      reel.isLiked = !wasLiked;
      reel.likesCount += wasLiked ? -1 : 1;
    });
    try {
      if (wasLiked)
        await _reelsService.removeLike(reel.id.toString());
      else
        await _reelsService.toggleLike(reel.id.toString());
    } catch (e) {
      setState(() {
        reel.isLiked = wasLiked;
        reel.likesCount += wasLiked ? 1 : -1;
      });
    }
  }

  Future<void> _handleShare(int index) async {
    final reel = _videos[index];
    final String reelUrl = 'https://linyora.com/reels/${reel.id}';
    await Share.share('شاهد هذا الفيديو: $reelUrl', subject: reel.description);
    try {
      await _reelsService.trackShare(reel.id.toString());
    } catch (_) {}
  }

  Future<void> _handleFollow(int index) async {
    if (_isProcessingFollow) return;
    final currentReel = _videos[index];
    if (currentReel.user == null) return;

    _isProcessingFollow = true;
    final int targetUserId = currentReel.user!.id;
    final bool newState = !currentReel.user!.isFollowing;

    setState(() {
      for (var video in _videos) {
        if (video.user?.id == targetUserId) video.user!.isFollowing = newState;
      }
    });

    try {
      await _profileService.toggleFollow(targetUserId, !newState);
      GlobalEventBus.sendEvent(targetUserId, newState);
    } catch (e) {
      setState(() {
        for (var video in _videos) {
          if (video.user?.id == targetUserId)
            video.user!.isFollowing = !newState;
        }
      });
    } finally {
      _isProcessingFollow = false;
    }
  }

  void _showComments(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CommentsSheet(
            reelId: _videos[index].id.toString(),
            service: _reelsService,
            onCommentAdded:
                () => setState(() => _videos[index].commentsCount++),
          ),
    );
  }
}



class ReelSkeleton extends StatelessWidget {
  const ReelSkeleton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned(
            bottom: 90,
            left: 16,
            right: 10,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[900]!,
              highlightColor: Colors.grey[700]!,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 200,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 80,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReelContentOverlay extends StatelessWidget {
  final ReelModel reel;
  final bool isLoading;
  final VoidCallback onLike, onComment, onShare, onFollow, onProfileTap;

  const ReelContentOverlay({
    Key? key,
    required this.reel,
    this.isLoading = false,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onFollow,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ الإصلاح: Positioned يجب أن يكون في القمة لكي يتعرف عليه الـ Stack
    return Positioned(
      bottom: 20,
      left: 16,
      right: 10,
      child: AbsorbPointer(
        // ✅ نقلنا وظيفة منع اللمس هنا
        absorbing: isLoading,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isLoading ? 0.0 : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onProfileTap,
                        child: Text(
                          '@${reel.user?.name ?? 'Unknown'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (reel.description != null)
                        Text(
                          reel.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.3,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 2),
                            ],
                          ),
                        ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    child: _ProfileFollowButton(
                      avatarUrl: reel.user?.avatar,
                      isFollowing: reel.user?.isFollowing ?? false,
                      onFollow: onFollow,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GlassyActionButton(
                    icon: reel.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${reel.likesCount}',
                    iconColor:
                        reel.isLiked ? const Color(0xFFFE2C55) : Colors.white,
                    onTap: onLike,
                  ),
                  const SizedBox(height: 16),
                  _GlassyActionButton(
                    icon: Icons.comment_rounded,
                    label: '${reel.commentsCount}',
                    onTap: onComment,
                  ),
                  const SizedBox(height: 16),
                  _GlassyActionButton(
                    icon: Icons.share_rounded,
                    label: 'مشاركة',
                    onTap: onShare,
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileFollowButton extends StatelessWidget {
  final String? avatarUrl;
  final bool isFollowing;
  final VoidCallback onFollow;
  const _ProfileFollowButton({
    required this.avatarUrl,
    required this.isFollowing,
    required this.onFollow,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey[800],
                backgroundImage:
                    (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(avatarUrl!)
                        : null,
                child:
                    (avatarUrl == null || avatarUrl!.isEmpty)
                        ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        )
                        : null,
              ),
            ),
          ),
          if (!isFollowing)
            Positioned(
              bottom: 0,
              child: GestureDetector(
                onTap: onFollow,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFE2C55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;
  const _GlassyActionButton({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 26,
                    color: iconColor,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}
