import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:linyora_project/features/categories/screens/category_products_screen.dart';
import 'package:linyora_project/features/home/screens/section_products_screen.dart';
import '../../../core/utils/color_helper.dart';
import '../../../models/section_model.dart';
import '../widgets/banner_video_player.dart';

class SectionDisplay extends StatelessWidget {
  final SectionModel section;

  const SectionDisplay({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    // 1. حسابات التجاوب (دون LayoutBuilder)
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    final Color themeColor = ColorHelper.fromHex(section.themeColor);
    final Color gradientColor = ColorHelper.adjustColor(
      themeColor,
      amount: -30,
    );

    return Column(
      children: [
        // --- 1. رأس القسم (Banner) ---
        Container(
          // نزيد الهوامش في التابلت
          margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 12 : 5,
            vertical: 4,
          ),
          // نزيد الارتفاع في التابلت
          height: isTablet ? 140 : 110,
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
              // خلفية جمالية
              Positioned(
                left: -30,
                top: -30,
                child: CircleAvatar(
                  radius: isTablet ? 70 : 50,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -20,
                child: CircleAvatar(
                  radius: isTablet ? 60 : 40,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),

              // المحتوى النصي
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
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
                          width: isTablet ? 55 : 40, // تكبير الأيقونة
                          height: isTablet ? 55 : 40,
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 24 : 20, // تكبير الخط
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
                              fontSize: isTablet ? 14 : 12, // تكبير الخط
                            ),
                          ),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    SectionDetailsScreen(sectionId: section.id),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: isTablet ? 25 : 20, // تكبير الزر
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.arrow_forward,
                          color: themeColor,
                          size: isTablet ? 28 : 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- 2. المحتوى المميز (منتج أو سلايدر) ---
        Container(
          // نزيد ارتفاع السلايدر في التابلت ليملأ الشاشة جمالياً
          height: isTablet ? 320 : 250,
          margin: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 5),
          child:
              section.featuredProductId != null
                  ? _buildFeaturedProduct(context, themeColor, isTablet)
                  : _buildSlideshow(context, isTablet),
        ),

        // --- 3. شريط التصنيفات (Categories Slider) ---
        if (section.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: SizedBox(
              height: 120,
              child: CarouselSlider.builder(
                itemCount: section.categories.length,
                options: CarouselOptions(
                  height: 130,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,

                  // التعديل الجوهري هنا:
                  // في التابلت، نعرض 5 عناصر (0.2)، في الموبايل 3.5 (0.28)
                  viewportFraction: isTablet ? 0.15 : 0.28,

                  enableInfiniteScroll: true,
                  padEnds: false,
                ),
                itemBuilder: (context, index, realIndex) {
                  final category = section.categories[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => CategoryProductsScreen(
                                  slug: category.slug,
                                  categoryName: category.name,
                                ),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height:
                                isTablet
                                    ? 75
                                    : 80, // تصغير بسيط ليناسب العرض المتعدد
                            width: isTablet ? 75 : 80,
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
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
                          SizedBox(
                            width: 80,
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
  Widget _buildFeaturedProduct(
    BuildContext context,
    Color themeColor,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: () {},
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: section.productImage ?? '',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
            ),
          ),
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
          Positioned(
            bottom: isTablet ? 24 : 16, // رفع النص قليلاً في التابلت
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.productName ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 22 : 18, // خط أكبر
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
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: themeColor,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 14 : 10,
                      ), // زر أكبر
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "تسوق الآن",
                      style: TextStyle(fontSize: isTablet ? 16 : 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت السلايدر
  Widget _buildSlideshow(BuildContext context, bool isTablet) {
    // ارتفاع ديناميكي
    final double sliderHeight = isTablet ? 320 : 250;

    if (section.slides.isEmpty) {
      return Container(
        height: sliderHeight,
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
        height: sliderHeight,
        viewportFraction: 1.0,
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 18 : 16, // خط أكبر
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
