import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:linyora_project/features/categories/screens/category_products_screen.dart';
import 'package:linyora_project/features/home/screens/section_products_screen.dart';
import 'package:linyora_project/features/products/screens/product_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/color_helper.dart';
import '../../../models/section_model.dart';
import '../widgets/banner_video_player.dart';

class SectionDisplay extends StatelessWidget {
  final SectionModel section;

  const SectionDisplay({super.key, required this.section});

  Future<void> _handleLinkTap(BuildContext context, String? link) async {
    if (link == null || link.isEmpty) return;

    // 1. معالجة الروابط الداخلية
    if (link.startsWith('/')) {
      // ✅ أ: إذا كان الرابط يخص منتجاً (مثال: /products/123)
      if (link.startsWith('/products/')) {
        // استخراج الـ ID من نهاية الرابط
        final String productId = link.split('/').last;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(productId: productId),
          ),
        );
        return;
      }

      // ✅ ب: إذا كان الرابط يخص قسماً (مثال: /sections/5)
      if (link.startsWith('/sections/')) {
        final int sectionId = int.tryParse(link.split('/').last) ?? 0;
        if (sectionId != 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SectionDetailsScreen(sectionId: sectionId),
            ),
          );
        }
        return;
      }

      // يمكن إضافة المزيد من الحالات هنا (مثل التصنيفات)
      return;
    }

    // 2. الروابط الخارجية (كما هي)
    final Uri url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
      }
    }
  }

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
    return InkWell(
      onTap: () {
        // يمكنك هنا فتح صفحة تفاصيل المنتج بدلاً من الرابط العام
        // أو استخدام الرابط الموجود في القسم
        _handleLinkTap(context, section.productLink);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // الخلفية (صورة المنتج)
          CachedNetworkImage(
            imageUrl: section.productImage ?? '',
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey[200]),
            errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported),
          ),

          // تدرج لوني للنص
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                stops: const [0.0, 0.6],
              ),
            ),
          ),

          // تفاصيل المنتج والزر
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "عرض خاص",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        section.productName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (section.productPrice != null)
                        Text(
                          "${section.productPrice} ﷼",
                          style: const TextStyle(
                            color: Colors.white, // لون أصفر للسعر
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),

                // زر الشراء الصغير
                ElevatedButton(
                  onPressed: () => _handleLinkTap(context, section.productLink),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "شراء",
                    style: TextStyle(fontWeight: FontWeight.bold),
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
    if (section.slides.isEmpty) return const SizedBox();

    return CarouselSlider(
      options: CarouselOptions(
        viewportFraction: 1.0,
        autoPlay: true,
        height: double.infinity, // لملء الحاوية الأب
        autoPlayInterval: const Duration(seconds: 4),
        enableInfiniteScroll: section.slides.length > 1,
      ),
      items:
          section.slides.map((slide) {
            return InkWell(
              onTap:
                  () => _handleLinkTap(
                    context,
                    slide.linkUrl,
                  ), // ✅ تشغيل رابط السلايد
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
                        width: double.infinity,
                      ),

                  // تراكب خفيف للنص (اختياري)
                  if (slide.title.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
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
                            fontWeight: FontWeight.bold,
                          ),
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
