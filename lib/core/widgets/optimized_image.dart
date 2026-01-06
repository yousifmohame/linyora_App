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
    // التصحيح: التحقق من أن العرض والارتفاع أرقام محدودة (ليست Infinity) قبل التحويل
    final int? cacheWidth =
        (width != null && width!.isFinite) ? (width! * 2.5).toInt() : null;

    final int? cacheHeight =
        (height != null && height!.isFinite) ? (height! * 2.5).toInt() : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // إذا كان العرض Infinity (مثل حالة ProductCard)، سيتم تمرير null هنا وسيعمل بشكل طبيعي
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget:
            (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
        fadeInDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}
