import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/utils/color_helper.dart';
import '../../../models/section_model.dart';
import '../widgets/banner_video_player.dart'; // سنعيد استخدام مشغل الفيديو

class SectionDisplay extends StatelessWidget {
  final SectionModel section;

  const SectionDisplay({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    // تحويل لون الثيم من Hex إلى Color
    final Color themeColor = ColorHelper.fromHex(section.themeColor);
    // لون ثانوي للتدرج (أغمق قليلاً)
    final Color gradientColor = ColorHelper.adjustColor(
      themeColor,
      amount: -30,
    );

    return Column(
      children: [
        // 1. رأس القسم (Banner)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          height: 110, // ارتفاع البانر
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [themeColor, gradientColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // دوائر خلفية جمالية
              Positioned(
                left: -30,
                top: -30,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -20,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),

              // المحتوى النصي
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    // الأيقونة
                    if (section.icon.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: section.icon,
                          width: 40,
                          height: 40,
                          color: Colors.white,
                        ),
                      ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            section.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            section.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // زر التصفح
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_forward, color: themeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. المحتوى المميز (منتج أو سلايدر)
        Container(
          height: 250,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child:
              section.featuredProductId != null
                  ? _buildFeaturedProduct(context, themeColor)
                  : _buildSlideshow(context),
        ),

        // 3. شبكة التصنيفات (Categories Grid)
        if (section.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
            ), // مسافة رأسية فقط
            child: SizedBox(
              height: 120, // تحديد ارتفاع الشريط
              child: CarouselSlider.builder(
                itemCount: section.categories.length,
                options: CarouselOptions(
                  height: 130,

                  // 1. تفعيل الحركة التلقائية
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3), // سرعة التقليب
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,

                  // 2. أهم إعداد: عرض عدة عناصر في وقت واحد
                  // القيمة 0.28 تعني ظهور حوالي 3.5 عنصر في الشاشة (شريط)
                  viewportFraction: 0.28,

                  // 3. التكرار اللانهائي
                  enableInfiniteScroll: true,
                  padEnds: false, // البدء من اليسار
                ),
                itemBuilder: (context, index, realIndex) {
                  final category = section.categories[index];

                  // نستخدم Container لإضافة هوامش جانبية بين العناصر
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: GestureDetector(
                      onTap: () {
                        // أكشن عند الضغط على التصنيف
                        print("Open Category: ${category.name}");
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // حاوية الصورة
                          Container(
                            height: 80,
                            width: 80, // جعلناها مربعة لتناسب الشريط
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(
                                16,
                              ), // حواف دائرية
                              border: Border.all(
                                color: themeColor.withOpacity(0.2),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: category.imageUrl,
                                fit: BoxFit.cover,
                                placeholder:
                                    (_, __) => const Center(
                                      child: Icon(
                                        Icons.category,
                                        color: Colors.grey,
                                      ),
                                    ),
                                errorWidget:
                                    (_, __, ___) => const Icon(Icons.error),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // اسم التصنيف
                          SizedBox(
                            width: 80, // نفس عرض الصورة لضمان توسيط النص
                            child: Text(
                              category.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  // ويدجت المنتج المميز
  Widget _buildFeaturedProduct(BuildContext context, Color themeColor) {
    return GestureDetector(
      onTap: () {
        // TODO: الانتقال لصفحة تفاصيل المنتج
        // Navigator.pushNamed(context, '/product', arguments: section.featuredProductId);
      },
      child: Stack(
        children: [
          // الصورة
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: section.productImage ?? '',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorWidget:
                  (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
            ),
          ),

          // طبقة داكنة
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),

          // بادج "مميز"
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "مميز",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // تفاصيل المنتج
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.productName ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (section.productPrice != null)
                  Text(
                    "${section.productPrice} ﷼",
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {}, // إضافة للسلة
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("تسوق الآن"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت السلايدر (إذا لم يكن هناك منتج)
  Widget _buildSlideshow(BuildContext context) {
    if (section.slides.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 50, color: Colors.grey),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 250,
        viewportFraction: 1.0, // عرض كامل
        autoPlay: true,
        enableInfiniteScroll: section.slides.length > 1,
      ),
      items:
          section.slides.map((slide) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  slide.mediaType == 'video'
                      ? BannerVideoPlayer(
                        videoUrl: slide.imageUrl,
                        isActive: true,
                        onVideoFinished: () {},
                      )
                      : CachedNetworkImage(
                        imageUrl: slide.imageUrl,
                        fit: BoxFit.cover,
                      ),

                  // نص الشريحة
                  Container(
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: Text(
                      slide.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
