import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class BannerVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final VoidCallback? onVideoFinished; // جعلتها اختيارية لتجنب الأخطاء

  const BannerVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isActive,
    this.onVideoFinished,
  });

  @override
  State<BannerVideoPlayer> createState() => _BannerVideoPlayerState();
}

class _BannerVideoPlayerState extends State<BannerVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  File? _videoFile;
  bool _isPreloading = false; // لمنع التحميل المتكرر

  @override
  void initState() {
    super.initState();
    _preloadFile();
  }

  Future<void> _preloadFile() async {
    if (_isPreloading) return;
    _isPreloading = true;

    try {
      // نستخدم الكاش مانجر لجلب الملف (يحمله مرة واحدة فقط)
      _videoFile = await DefaultCacheManager().getSingleFile(widget.videoUrl);

      if (mounted && widget.isActive) {
        _initializeVideo();
      }
    } catch (e) {
      debugPrint("Error preloading file: $e");
    } finally {
      _isPreloading = false;
    }
  }

  @override
  void didUpdateWidget(BannerVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _initializeVideo();
      } else {
        // ✅ هنا نمرر true لأننا ما زلنا في الشاشة ونريد إخفاء الفيديو
        _disposeController(updateUI: true);
      }
    }
  }

  Future<void> _initializeVideo() async {
    // إذا لم يكن الملف جاهزاً أو الفيديو يعمل بالفعل، لا تفعل شيئاً
    if (_videoFile == null || _controller != null) return;

    try {
      final controller = VideoPlayerController.file(
        _videoFile!,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      _controller = controller; // تعيينه قبل الـ await لمنع التكرار

      await controller.initialize();
      controller.setVolume(0.0); // كتم الصوت للبنرات
      controller.setLooping(false);

      controller.addListener(_videoListener);

      // ✅ فحص أمان مزدوج: هل ما زال الودجت موجوداً؟ وهل ما زال نشطاً؟
      if (!mounted || !widget.isActive) {
        // إذا تغيرت الحالة أثناء التحميل، تخلص منه فوراً
        _disposeController(updateUI: false);
        return;
      }

      setState(() {
        _isInitialized = true;
      });

      controller.play();
    } catch (e) {
      debugPrint("Init Error: $e");
      _disposeController(updateUI: true); // تنظيف في حال الخطأ
      if (widget.onVideoFinished != null) widget.onVideoFinished!();
    }
  }

  void _videoListener() {
    final controller = _controller;
    if (controller != null &&
        controller.value.position >= controller.value.duration) {
      if (widget.onVideoFinished != null) widget.onVideoFinished!();
    }
  }

  // ✅ التعديل الجوهري: إضافة معامل updateUI
  void _disposeController({required bool updateUI}) {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;

    if (updateUI && mounted) {
      setState(() {
        _isInitialized = false;
      });
    } else {
      // إذا كنا نغلق الصفحة، نغير المتغير فقط بدون setState
      _isInitialized = false;
    }
  }

  @override
  void dispose() {
    // 🛑 هام جداً: نمرر false هنا لمنع الـ Crash
    _disposeController(updateUI: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black, // أو صورة Placeholder إذا توفرت
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
