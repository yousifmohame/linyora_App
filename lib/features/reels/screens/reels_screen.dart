import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart'; // مكتبة المشغل
import 'package:video_player/video_player.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart'; // مكتبة التحميل الجمالي

// --- استيرادات مشروعك (لا تغيرها) ---
import 'package:linyora_project/core/utils/event_bus.dart';
import 'package:linyora_project/features/public_profiles/screens/model_profile_screen.dart';
import 'package:linyora_project/features/public_profiles/services/public_profile_service.dart';
import 'package:linyora_project/features/reels/screens/widgets/comments_sheet.dart';
import 'package:linyora_project/models/reel_model.dart';
import '../../../../core/utils/video_cache_manager.dart';
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
  bool _interactionUnlocked = false; // فتح التفاعل بعد التشغيل
  bool _isAudioFadedIn = false; // صوت fade-in

  // --- أدوات الاحترافية ---
  Timer? _scrollDebounceTimer;
  ScrollPhysics _scrollPhysics = const NeverScrollableScrollPhysics();

  // ---------------------------------------------------------------------------
  // Lifecycle Methods
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReels();
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _pauseAll();
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
      _pauseAll();
    } else if (widget.isActive) {
      // فقط شغل إذا كانت الصفحة نشطة
      _forcePlayAtIndex(_focusedIndex);
    }
  }

  @override
  void didUpdateWidget(ReelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // هذا الكود يعمل عند التنقل بين التابات
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _forcePlayAtIndex(_focusedIndex);
      } else {
        _pauseAll();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Data Loading
  // ---------------------------------------------------------------------------

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
      debugPrint("Error loading reels data");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Page Navigation Logic
  // ---------------------------------------------------------------------------

  void _onPageChanged(int index) {
    _pauseAll();
    _scrollDebounceTimer?.cancel();

    setState(() {
      _focusedIndex = index;
      _interactionUnlocked = false;
      _scrollPhysics = const NeverScrollableScrollPhysics(); // قفل التمرير
    });

    _collectGarbage(index);

    _scrollDebounceTimer = Timer(const Duration(milliseconds: 50), () async {
      if (!mounted || !_isAppActive || !widget.isActive) return;

      await _initAndPlay(index);

      final next = index + 1;
      if (next < _videos.length) _preload(next);
    });
  }

  // ---------------------------------------------------------------------------
  // Video Logic
  // ---------------------------------------------------------------------------

  void _pauseAll() {
    for (final c in _controllers.values) {
      if (c.videoPlayerController.value.isPlaying) {
        c.pause();
      }
      if (c.videoPlayerController.value.isPlaying) {
        c.videoPlayerController.pause();
      }
    }
  }

  void _fadeInVolume(VideoPlayerController controller) async {
    double volume = 0.0;
    const step = 0.05;
    const delay = Duration(milliseconds: 15);

    while (volume < 1.0) {
      await Future.delayed(delay);
      volume += step;
      if (!mounted) break;
      if (!controller.value.isInitialized) break;
      controller.setVolume(volume.clamp(0.0, 1.0));
    }
    controller.setVolume(1.0);
  }

  // === الدالة المسؤولة عن التشغيل (تم التعديل هنا) ===
  void _forcePlayAtIndex(int index) {
    // 1. شرط الحماية الأهم: إذا لم تكن هذه الصفحة هي المعروضة، لا تشغل شيئاً
    if (!widget.isActive) return;

    final c = _controllers[index];
    if (c == null ||
        !c.videoPlayerController.value.isInitialized ||
        index != _focusedIndex) {
      return;
    }

    final videoCtrl = c.videoPlayerController;

    // البدء بصوت مكتوم لتجنب الإزعاج المفاجئ
    videoCtrl.setVolume(0.0);
    videoCtrl.seekTo(Duration.zero);
    c.play();

    _isAudioFadedIn = false;
    _interactionUnlocked = false;

    // مستمع لفتح التفاعل فقط عندما يبدأ الفيديو بالتحرك فعلياً
    void listener() {
      final value = videoCtrl.value;

      if (value.isPlaying &&
          value.position >= const Duration(milliseconds: 200)) {
        videoCtrl.removeListener(listener);

        if (!mounted || index != _focusedIndex) return;

        // الفيديو يعمل الآن => افتح التفاعل والتمرير
        setState(() {
          _interactionUnlocked = true;
          _scrollPhysics = const AlwaysScrollableScrollPhysics();
        });

        // رفع الصوت تدريجياً (Fade In)
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
      final file = await VideoCacheUtils.getCachedVideoFile(reel.videoUrl);

      final videoCtrl = VideoPlayerController.file(file);
      await videoCtrl.initialize();

      if (!mounted || index != _focusedIndex) {
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
        placeholder: Container(color: Colors.black),
      );

      setState(() => _controllers[index] = chewie);

      // هنا يتم استدعاء دالة التشغيل، لكنها لن تعمل إلا إذا كان widget.isActive == true
      _forcePlayAtIndex(index);
    } catch (e) {
      debugPrint("Error initializing video $index: $e");
      // في حالة الخطأ، نفتح التمرير لكي لا يعلق المستخدم
      if (mounted) {
        setState(() {
          _scrollPhysics = const AlwaysScrollableScrollPhysics();
        });
      }
    }
  }

  Future<void> _preload(int index) async {
    if (_controllers.containsKey(index) || index >= _videos.length) return;
    try {
      final file = await VideoCacheUtils.getCachedVideoFile(
        _videos[index].videoUrl,
      );
      final videoCtrl = VideoPlayerController.file(file);
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
      _controllers[k]?.dispose();
      _controllers.remove(k);
    });
  }

  void _disposeAllControllers() {
    for (final c in _controllers.values) c.dispose();
    _controllers.clear();
  }

  // ---------------------------------------------------------------------------
  // Build UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: ReelSkeleton()),
      );
    }

    if (_videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "لا توجد فيديوهات",
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
        physics: _scrollPhysics,
        itemCount: _videos.length,
        preloadPagesCount: 0,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final controller = _controllers[index];
          final isReady =
              controller != null &&
              controller.videoPlayerController.value.isInitialized;

          return Stack(
            fit: StackFit.expand,
            children: [
              // الطبقة 1: الفيديو أو السكيلتون
              if (isReady)
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

              // الطبقة 2: التفاعل واللمس
              // لن تظهر إلا إذا كان الفيديو جاهزاً + تم فتح قفل التفاعل (بعد بدء التشغيل)
              if (isReady && _interactionUnlocked)
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

              // الطبقة 3: أيقونة التشغيل
              if (isReady && _interactionUnlocked && !controller.isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 80,
                    color: Colors.white60,
                  ),
                ),

              // الطبقة 4: الظل
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

              // الطبقة 5: المحتوى
              AbsorbPointer(
                absorbing: !isReady,
                child: ReelContentOverlay(
                  reel: _videos[index],
                  isLoading: !isReady,
                  onLike: () => _handleLike(index),
                  onComment: () => _showComments(context, index),
                  onShare: () => _handleShare(index),
                  onFollow: () => _handleFollow(index),
                  onProfileTap: () {
                    _controllers[index]?.pause();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ModelProfileScreen(
                              modelId: _videos[index].user!.id.toString(),
                            ),
                      ),
                    ).then((_) {
                      // عند العودة، شغل الفيديو فقط إذا كنا ما زلنا في صفحة الريلز
                      if (widget.isActive) _forcePlayAtIndex(index);
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Actions ---
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

// -----------------------------------------------------------------------------
// --- Reel Skeleton & Overlay Widgets ---
// -----------------------------------------------------------------------------

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
                        const SizedBox(height: 6),
                        Container(
                          width: 150,
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
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isLoading ? 0.0 : 1.0,
      child: Positioned(
        bottom: 20,
        left: 16,
        right: 10,
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
                        '${reel.user?.name ?? 'Unknown'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
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
                    const SizedBox(height: 12),
                    if (reel.products != null && reel.products!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            color: Colors.white.withOpacity(0.15),
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
                                  'تسوق ${reel.products!.length} منتجات',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 110),
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
