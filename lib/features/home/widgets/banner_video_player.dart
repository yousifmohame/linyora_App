import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class BannerVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final VoidCallback onVideoFinished;

  const BannerVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isActive,
    required this.onVideoFinished,
  });

  @override
  State<BannerVideoPlayer> createState() => _BannerVideoPlayerState();
}

class _BannerVideoPlayerState extends State<BannerVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  File? _videoFile; // نحتفظ بالملف حتى لا نحمله كل مرة

  @override
  void initState() {
    super.initState();
    // تحميل الملف فقط، لا تقم بتهيئة الفيديو بعد
    _preloadFile();
  }

  Future<void> _preloadFile() async {
    try {
      _videoFile = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      if (mounted && widget.isActive) {
        _initializeVideo();
      }
    } catch (e) {
      debugPrint("Error preloading file: $e");
    }
  }

  @override
  void didUpdateWidget(BannerVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🧠 المخ: التحكم في الموارد
    if (widget.isActive && !oldWidget.isActive) {
      // إذا أصبح البانر مرئياً -> هيّئ الفيديو وشغله
      _initializeVideo();
    } else if (!widget.isActive && oldWidget.isActive) {
      // إذا اختفى البانر -> دمر الفيديو فوراً لتحرير الموارد
      _disposeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (_videoFile == null || _controller != null) return;

    try {
      _controller = VideoPlayerController.file(
        _videoFile!,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _controller!.initialize();
      _controller!.setVolume(0.0);
      _controller!.setLooping(false);

      _controller!.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
      }
    } catch (e) {
      debugPrint("Init Error: $e");
      // في حالة الفشل، نبلغ أن الفيديو انتهى للانتقال للتالي
      widget.onVideoFinished();
    }
  }

  void _videoListener() {
    if (_controller != null &&
        _controller!.value.position >= _controller!.value.duration) {
      widget.onVideoFinished();
    }
  }

  void _disposeVideo() {
    // تدمير المتحكم لتحرير الـ Decoder في الهاتف
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;
    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إذا لم يكن مهيأ، اعرض صورة سوداء أو لودينج
    // هذا يمنع الوميض بينما يتم تحضير الـ Decoder
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black, // يفضل وضع صورة مصغرة (Thumbnail) هنا لو توفرت
        child: const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
