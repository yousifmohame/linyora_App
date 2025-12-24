import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد حجم الكاش بناءً على الحجم المطلوب (لتقليل استهلاك الرامات)
    final int? cacheWidth = width != null ? (width! * 2.5).toInt() : null; // نضرب في 2.5 للشاشات عالية الدقة
    final int? cacheHeight = height != null ? (height! * 2.5).toInt() : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // 👇 هذا هو السر: تحديد حجم الصورة في الذاكرة
        memCacheWidth: cacheWidth, 
        memCacheHeight: cacheHeight,
        // عرض مربع رمادي خفيف بدلاً من لودينج ثقيل
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
        fadeInDuration: const Duration(milliseconds: 200), // تقليل وقت الأنيميشن
      ),
    );
  }
}