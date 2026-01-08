import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

// --- استيرادات مشروعك ---
import 'package:linyora_project/core/utils/event_bus.dart';
import 'package:linyora_project/features/public_profiles/screens/model_profile_screen.dart';
import 'package:linyora_project/features/public_profiles/services/public_profile_service.dart';
import 'package:linyora_project/features/reels/screens/widgets/comments_sheet.dart';
import 'package:linyora_project/models/reel_model.dart';
import '../services/reels_service.dart';
import '../controllers/reel_video_controller.dart';

class ReelsScreen extends StatefulWidget {
  final bool isActive;
  const ReelsScreen({Key? key, required this.isActive}) : super(key: key);

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with TickerProviderStateMixin {
  final ReelsService _reelsService = ReelsService();
  final PublicProfileService _profileService = PublicProfileService();
  final PreloadPageController _pageController = PreloadPageController();

  final Map<int, ReelVideoController> _videoControllers = {};
  List<ReelModel> _videos = [];
  bool _isLoading = true;
  int _focusedIndex = 0;
  bool _isAppActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _loadReels();
  }

  late final WidgetsBindingObserver _lifecycleObserver = _AppLifecycleObserver(
    onResume: () {
      _isAppActive = true;
      if (widget.isActive) _playVideoAt(_focusedIndex);
    },
    onPause: () {
      _isAppActive = false;
      _pauseAll();
    },
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _disposeAll();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _playVideoAt(_focusedIndex);
      } else {
        _pauseAll();
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
        await _initController(0);
        if (widget.isActive) _playVideoAt(0);
        _preloadNext(1);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPageChanged(int index) {
    _pauseAll();
    setState(() => _focusedIndex = index);

    _garbageCollect(index);

    _initController(index).then((_) {
      if (mounted && widget.isActive && _isAppActive) {
        _playVideoAt(index);
      }
    });

    _preloadNext(index + 1);
  }

  Future<void> _initController(int index) async {
    if (index < 0 || index >= _videos.length) return;
    if (_videoControllers.containsKey(index)) return;

    final controller = ReelVideoController(
      videoUrl: _videos[index].videoUrl,
      vsync: this,
      onStateChanged: (isPlaying, isBuffering) {
        if (mounted && index == _focusedIndex) setState(() {});
      },
    );

    _videoControllers[index] = controller;
    await controller.initialize();

    if (mounted) setState(() {});
  }

  void _preloadNext(int index) {
    if (index < _videos.length) {
      DefaultCacheManager().downloadFile(_videos[index].videoUrl);
    }
  }

  void _playVideoAt(int index) {
    // ✅ التصحيح 2: حماية من تشغيل الفيديو الخطأ (في حالة السكرول السريع)
    if (index != _focusedIndex) return;

    final controller = _videoControllers[index];
    if (controller != null && controller.isInitialized) {
      controller.play();
    }
  }

  void _pauseAll() {
    for (var c in _videoControllers.values) {
      c.pause();
    }
  }

  void _garbageCollect(int currentIndex) {
    _videoControllers.keys
        .where((key) {
          return key < currentIndex - 1 || key > currentIndex + 1;
        })
        .toList()
        .forEach((key) {
          _videoControllers[key]?.dispose();
          _videoControllers.remove(key);
        });
  }

  void _disposeAll() {
    for (var c in _videoControllers.values) c.dispose();
    _videoControllers.clear();
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
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _videos.length,
        preloadPagesCount: 0,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final controller = _videoControllers[index];
          final isReady = controller != null && controller.isInitialized;

          return Stack(
            fit: StackFit.expand,
            children: [
              if (isReady && controller.chewieController != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.videoPlayerController!.value.size.width,
                    height: controller.videoPlayerController!.value.size.height,
                    child: Chewie(controller: controller.chewieController!),
                  ),
                )
              else
                const ReelSkeleton(),

              if (isReady && controller.isBuffering)
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

              if (isReady)
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

              if (isReady && !controller.isPlaying && !controller.isBuffering)
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 80,
                    color: Colors.white60,
                  ),
                ),

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

              Positioned(
                bottom: 20,
                left: 16,
                right: 10,
                child: AbsorbPointer(
                  absorbing: !isReady,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isReady ? 1.0 : 0.0,
                    child: ReelContentOverlay(
                      reel: _videos[index],
                      isLoading: !isReady,
                      onLike: () => _handleLike(index),
                      onComment: () => _showComments(context, index),
                      onShare: () => _handleShare(index),
                      onFollow: () => _handleFollow(index),
                      onProfileTap: () {
                        _pauseAll();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ModelProfileScreen(
                                  modelId: _videos[index].user!.id.toString(),
                                ),
                          ),
                        ).then((_) {
                          if (widget.isActive) _playVideoAt(index);
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

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
    await Share.share(
      'شاهد هذا الفيديو: https://linyora.com/reels/${_videos[index].id}',
    );
    try {
      await _reelsService.trackShare(_videos[index].id.toString());
    } catch (_) {}
  }

  Future<void> _handleFollow(int index) async {
    final user = _videos[index].user;
    if (user == null) return;

    final newState = !user.isFollowing;
    setState(() {
      for (var v in _videos) {
        if (v.user?.id == user.id) v.user!.isFollowing = newState;
      }
    });

    try {
      await _profileService.toggleFollow(user.id, !newState);
      GlobalEventBus.sendEvent(user.id, newState);
    } catch (_) {
      setState(() {
        for (var v in _videos) {
          if (v.user?.id == user.id) v.user!.isFollowing = !newState;
        }
      });
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

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  final VoidCallback onPause;
  _AppLifecycleObserver({required this.onResume, required this.onPause});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    } else {
      onPause();
    }
  }
}

// -----------------------------------------------------------------------------
// --- Widgets المساعدة (لم تتغير) ---
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
    required this.isLoading,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onFollow,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
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
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
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
                      shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
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
              iconColor: reel.isLiked ? const Color(0xFFFE2C55) : Colors.white,
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
