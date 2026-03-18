import 'dart:async'; // 👈 ضروري للتايمر
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ 1. استيراد ملف الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

// تأكد من صحة مسارات الملفات التالية حسب مشروعك
import 'package:linyora_project/features/shared/widgets/background_video_player.dart';
import 'package:linyora_project/features/shared/widgets/product_card.dart';
import '../../../core/utils/hex_color.dart';
import '../../home/services/section_service.dart';
import '../../../models/section_model.dart';
import '../../../models/product_model.dart';

class SectionDetailsScreen extends StatefulWidget {
  final int sectionId;

  const SectionDetailsScreen({Key? key, required this.sectionId})
    : super(key: key);

  @override
  State<SectionDetailsScreen> createState() => _SectionDetailsScreenState();
}

class _SectionDetailsScreenState extends State<SectionDetailsScreen> {
  final SectionService _service = SectionService();

  // متغيرات البيانات
  SectionModel? _section;
  List<ProductModel> _products = [];
  bool _isLoading = true;

  // متغيرات السلايدر (للتحريك التلقائي والنقاط)
  int _currentSlideIndex = 0;
  final PageController _pageController = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _timer?.cancel(); // إيقاف التايمر عند الخروج لمنع تسريب الذاكرة
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final section = await _service.getSectionById(widget.sectionId);

      // إذا خرج المستخدم من الصفحة، نوقف التنفيذ
      if (!mounted) return;

      if (section != null) {
        List<ProductModel> products = [];
        // جلب المنتجات فقط إذا كان هناك تصنيفات مربوطة
        if (section.categoryIds.isNotEmpty) {
          products = await _service.getProductsByCategories(
            section.categoryIds,
          );
        }

        if (mounted) {
          setState(() {
            _section = section;
            _products = products;
            _isLoading = false;
          });
          // ✅ بدء التحريك التلقائي بعد تحميل البيانات
          _startAutoPlay();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error in Section Details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // دالة التحريك التلقائي للسلايدر
  void _startAutoPlay() {
    if (_section == null || _section!.slides.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentSlideIndex < _section!.slides.length - 1) {
        _currentSlideIndex++;
      } else {
        _currentSlideIndex = 0; // العودة للأول
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentSlideIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // توليد التدرج اللوني من لون الثيم
  List<Color> _generateGradient(String hexColor) {
    Color color1 = HexColor.fromHex(hexColor);
    // معادلة تقريبية للحصول على اللون الثانوي كما في الموقع
    int r = color1.red;
    int g = (color1.green - 3).clamp(0, 255);
    int b = (color1.blue + 110).clamp(0, 255);
    Color color2 = Color.fromARGB(255, r, g, b);
    return [color2, color1];
  }

  // فتح الروابط الخارجية
  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة مرة واحدة في دالة البناء
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF105C6)),
        ),
      );
    }

    if (_section == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(child: Text(l10n.sectionUnavailable)), // ✅ مترجم
      );
    }

    final gradientColors = _generateGradient(_section!.themeColor);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. الهيدر المتدرج (Sticky Header)
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            toolbarHeight: 60,
            leading: const BackButton(color: Colors.white),
            title: Text(
              _section!.title, // هذا النص يأتي من قاعدة البيانات
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: gradientColors,
                ),
              ),
            ),
          ),

          // 2. السلايدر (Slides) مع النقاط والتحريك
          if (_section!.slides.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _section!.slides.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentSlideIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final slide = _section!.slides[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // الخلفية (فيديو أو صورة)
                            if (slide.mediaType == 'video')
                              BackgroundVideoPlayer(videoUrl: slide.imageUrl)
                            else
                              CachedNetworkImage(
                                imageUrl: slide.imageUrl,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) =>
                                        Container(color: Colors.grey[200]),
                                errorWidget:
                                    (context, url, error) =>
                                        const Icon(Icons.error),
                              ),

                            // طبقة سوداء شفافة لتحسين قراءة النص
                            Container(color: Colors.black.withOpacity(0.3)),

                            // المحتوى النصي والأزرار
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 40,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    slide.title, // هذا النص يأتي من قاعدة البيانات
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (slide.description.isNotEmpty)
                                    Text(
                                      slide.description, // هذا النص يأتي من قاعدة البيانات
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black45,
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (slide.buttonText.isNotEmpty) ...[
                                    const SizedBox(height: 25),
                                    ElevatedButton(
                                      onPressed:
                                          () => _launchUrl(slide.buttonLink),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: HexColor.fromHex(
                                          _section!.themeColor,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 30,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      child: Text(slide.buttonText), // زر يأتي نصه من قاعدة البيانات
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // مؤشرات الصفحات (Dots)
                    if (_section!.slides.length > 1)
                      Positioned(
                        bottom: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _section!.slides.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              // النقطة النشطة تكون أعرض
                              width: _currentSlideIndex == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color:
                                    _currentSlideIndex == index
                                        ? HexColor.fromHex(_section!.themeColor)
                                        : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 3. عنوان القسم وتفاصيله (أسفل السلايدر)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _section!.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: HexColor.fromHex(_section!.themeColor),
                    ),
                  ),
                  if (_section!.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _section!.description,
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 4. شبكة المنتجات
          _products.isEmpty
              ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 50,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(l10n.noProductsAvailable), // ✅ مترجم
                      ],
                    ),
                  ),
                ),
              )
              : SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return ProductCard(product: _products[index]);
                }, childCount: _products.length),
              ),

          // مساحة إضافية في الأسفل
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}