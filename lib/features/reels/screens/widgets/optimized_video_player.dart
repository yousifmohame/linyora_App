import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class OptimizedVideoPlayer extends StatefulWidget {
  final VideoPlayerController? controller;
  
  const OptimizedVideoPlayer({Key? key, required this.controller}) : super(key: key);

  @override
  State<OptimizedVideoPlayer> createState() => _OptimizedVideoPlayerState();
}

class _OptimizedVideoPlayerState extends State<OptimizedVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    // 1. حالة التحميل (إذا لم يكن الكنترولر جاهزاً)
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    // 2. حالة العرض
    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
        setState(() {}); // تحديث الأيقونة إذا أردت إظهار أيقونة التشغيل/الإيقاف
      },
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}