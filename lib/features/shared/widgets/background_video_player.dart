import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const BackgroundVideoPlayer({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<BackgroundVideoPlayer> createState() => _BackgroundVideoPlayerState();
}

class _BackgroundVideoPlayerState extends State<BackgroundVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // إعداد الفيديو
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        // بمجرد التحميل، ابدأ التشغيل
        _controller.play();
        _controller.setLooping(true); // تكرار الفيديو
        _controller.setVolume(0.0); // كتم الصوت (لأنه خلفية)
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // تنظيف الذاكرة مهم جداً
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover, // لتعبئة المساحة بالكامل مثل الصور
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      );
    } else {
      // عرض مؤشر تحميل حتى يجهز الفيديو
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
  }
}