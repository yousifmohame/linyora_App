import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
// --- Services & Models ---
import 'package:linyora_project/features/home/services/section_service.dart';
import 'package:linyora_project/features/home/services/home_service.dart';
import 'package:linyora_project/features/home/widgets/marquee_widget.dart';
import 'package:linyora_project/models/product_model.dart';
import 'package:linyora_project/models/section_model.dart';
import 'package:linyora_project/models/banner_model.dart';
import 'package:linyora_project/models/category_model.dart';
import 'package:linyora_project/models/top_user_model.dart';

// --- Widgets ---
import 'package:linyora_project/features/home/widgets/flash_sale_section.dart';
import 'package:linyora_project/features/home/widgets/horizontal_product_list.dart';
import 'package:linyora_project/features/stories/widgets/stories_section.dart';
import '../widgets/section_display.dart';
import '../widgets/banner_video_player.dart';
import '../widgets/top_user_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. Services & Controllers
  final HomeService _homeService = HomeService();
  final SectionService _sectionService = SectionService();
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  // 2. Data Lists
  List<BannerModel> _banners = [];
  List<CategoryModel> _categories = [];
  List<SectionModel> _sections = [];
  List<TopUserModel> _topModels = [];
  List<TopUserModel> _topMerchants = [];
  List<ProductModel> _newArrivals = [];
  List<ProductModel> _bestSellers = [];
  List<ProductModel> _topRated = [];

  // 3. State Variables
  bool _isLoading = true;
  int _currentBannerIndex = 0;
  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    super.dispose();
  }

  // --- Logic Methods ---

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _homeService.getBanners(), // 0
        _homeService.getCategories(), // 1
        _sectionService.getActiveSections(), // 2
        _homeService.getTopModels(), // 3
        _homeService.getTopMerchants(), // 4
        _homeService.getProductsByType('new'), // 5
        _homeService.getProductsByType('best'), // 6
        _homeService.getProductsByType('top'), // 7
      ]);

      if (mounted) {
        setState(() {
          _banners = results[0] as List<BannerModel>;
          _categories = results[1] as List<CategoryModel>;
          _sections = results[2] as List<SectionModel>;
          _topModels = results[3] as List<TopUserModel>;
          _topMerchants = results[4] as List<TopUserModel>;
          _newArrivals = results[5] as List<ProductModel>;
          _bestSellers = results[6] as List<ProductModel>;
          _topRated = results[7] as List<ProductModel>;
          _isLoading = false;
        });

        // تشغيل المنطق الذكي للبانرات
        if (_banners.isNotEmpty) _handleAutoPlay(0);
      }
    } catch (e) {
      debugPrint("Error loading home data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAutoPlay(int index) {
    _sliderTimer?.cancel();
    // إذا كان فيديو ننتظر انتهاءه، إذا صورة ننتظر 5 ثواني
    if (!_banners[index].isVideo) {
      _sliderTimer = Timer(const Duration(seconds: 5), () {
        _carouselController.nextPage();
      });
    }
  }

  // --- UI Builder Methods (لتقسيم الكود) ---

  Widget _buildAppBar() {
    return SliverAppBar(
      // 1. الخصائص الأساسية
      floating: true, // يظهر عند السحب لأعلى
      pinned: true, // يبقى الجزء العلوي ثابتاً (اللوجو)
      snap: true, // يظهر بسرعة عند أدنى حركة
      backgroundColor: Colors.white,
      elevation: 0, // إزالة الظل الافتراضي لجعله مسطحاً
      surfaceTintColor:
          Colors.white, // منع تغيير اللون عند السكرول في Material 3
      // 2. الجزء الأيسر (القائمة أو اللوجو)
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () {
          // فتح الـ Drawer
        },
      ),

      // 3. العنوان (اسم التطبيق)
      title: const Text(
        "Linyora",
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Playfair Display', // يفضل استخدام خط فخم
          fontWeight: FontWeight.w900,
          fontSize: 24,
          letterSpacing: 1.2,
        ),
      ),
      centerTitle: true,

      // 4. الأيقونات (تنبيهات + سلة)
      actions: [
        // أيقونة البحث (اختياري هنا لأننا سنضع شريط بحث بالأسفل)
        // IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {}),

        // أيقونة التنبيهات مع نقطة حمراء
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black,
                size: 28,
              ),
              onPressed: () {},
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),

        // أيقونة السلة (مهمة جداً)
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.shopping_cart,
                color: Colors.black,
                size: 28,
              ),
              onPressed: () {},
            ),
            Positioned(
              top: 3,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  "2", // رقم ثابت للتجربة
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],

      // 5. الجزء السفلي (شريط البحث) - هذا ما يجعله احترافياً
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70.0), // ارتفاع شريط البحث
        child: Container(
          height: 70,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              // الانتقال لصفحة البحث
            },
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100], // لون خلفية خفيف جداً
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    "عن ماذا تبحث اليوم؟",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const Spacer(),
                  // أيقونة الكاميرا أو الفلتر (حركة احترافية)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannersSection() {
    if (_banners.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 220.0,
            autoPlay: false, // تحكم يدوي
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            enableInfiniteScroll: true,
            pageSnapping: true,
            scrollPhysics: const BouncingScrollPhysics(),
            onPageChanged: (index, reason) {
              setState(() => _currentBannerIndex = index);
              _handleAutoPlay(index);
            },
          ),
          items:
              _banners.asMap().entries.map((entry) {
                int index = entry.key;
                var banner = entry.value;
                bool isActive = index == _currentBannerIndex;

                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black12,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // الخلفية (فيديو أو صورة)
                            banner.isVideo
                                ? BannerVideoPlayer(
                                  videoUrl: banner.imageUrl,
                                  isActive: isActive,
                                  onVideoFinished: () {
                                    if (isActive)
                                      _carouselController.nextPage();
                                  },
                                )
                                : CachedNetworkImage(
                                  imageUrl: banner.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (_, __) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  errorWidget:
                                      (_, __, ___) => const Icon(Icons.error),
                                ),
                            // التظليل والنص
                            _buildBannerOverlay(banner),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildBannerOverlay(BannerModel banner) {
    return Stack(
      children: [
        // تدرج لوني لضمان وضوح النص
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.8), // زدت التغميق قليلاً في الأسفل
                Colors.transparent,
              ],
            ),
          ),
        ),

        // النصوص والزر
        Padding(
          padding: const EdgeInsets.all(20), // حاشية أكبر قليلاً
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. العنوان
              Text(
                banner.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20, // تكبير الخط
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                ),
              ),

              // 2. الوصف
              if (banner.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  banner.subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 3. الزر (يظهر فقط إذا كان هناك نص للزر)
              if (banner.buttonText.isNotEmpty) ...[
                const SizedBox(height: 12), // مسافة قبل الزر
                SizedBox(
                  height: 36, // ارتفاع الزر
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: فتح الرابط هنا
                      // مثال: Navigator.pushNamed(context, banner.link);
                      print("Navigating to: ${banner.link}");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // خلفية بيضاء
                      foregroundColor: Colors.black, // نص أسود
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // حواف دائرية
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min, // الزر يأخذ حجم المحتوى فقط
                      children: [
                        Text(
                          banner.buttonText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                        ), // سهم صغير
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final category = _categories[index];
          return Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    image:
                        category.imageUrl.isNotEmpty
                            ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                category.imageUrl,
                              ),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      category.imageUrl.isEmpty
                          ? const Icon(Icons.category, color: Colors.grey)
                          : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }, childCount: _categories.length),
      ),
    );
  }

  Widget _buildSectionTitleWrapper(String title, VoidCallback onSeeAll) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                "عرض الكل",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUsersList(List<TopUserModel> users, {required bool isModel}) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: users.length,
          itemBuilder: (context, index) {
            return TopUserCard(user: users[index], isModel: isModel);
          },
        ),
      ),
    );
  }

  // دالة لإنشاء الفاصل
  Widget _buildDivider() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Container(
          height:
              2, // سمك الفاصل (يمكنك جعله 1 لخط رفيع، أو 8 لفصل الأقسام بوضوح)
          color: Colors.pink, // لون رمادي فاتح جداً
        ),
      ),
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  // 1. App Bar
                  _buildAppBar(),

                  const SliverToBoxAdapter(child: MarqueeWidget()),

                  // 2. Stories
                  const SliverToBoxAdapter(child: StoriesSection()),

                  // 3. Banners Slider
                  _buildBannersSection(),

                  // 4. Flash Sale
                  const SliverToBoxAdapter(child: FlashSaleSection()),

                  // 5. Categories Header & Grid
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: Text(
                        "تسوق حسب القسم",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _buildCategoriesSection(),

                  _buildDivider(),

                  SliverToBoxAdapter(
                    child: HorizontalProductList(
                      title: "وصل حديثاً 🆕",
                      products: _newArrivals,
                      onSeeAll: () {},
                    ),
                  ),

                  _buildDivider(),
                  // 6. Dynamic Sections (قائمة الأقسام المتغيرة)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          SectionDisplay(section: _sections[index]),
                      childCount: _sections.length,
                    ),
                  ),

                  _buildDivider(),

                  // 7. Top Models
                  if (_topModels.isNotEmpty) ...[
                    _buildSectionTitleWrapper("أشهر العارضات ✨", () {}),
                    _buildTopUsersList(_topModels, isModel: true),
                  ],

                  _buildDivider(),

                  // 8. Top Merchants
                  if (_topMerchants.isNotEmpty) ...[
                    _buildSectionTitleWrapper("متاجر مميزة 🛍️", () {}),
                    _buildTopUsersList(_topMerchants, isModel: false),
                  ],

                  _buildDivider(),

                  // 9. Horizontal Product Lists (وصل حديثاً، الأكثر مبيعاً، الأعلى تقييماً)
                  SliverToBoxAdapter(
                    child: HorizontalProductList(
                      title: "الأكثر مبيعاً 🔥",
                      products: _bestSellers,
                      onSeeAll: () {},
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HorizontalProductList(
                      title: "الأعلى تقييماً ⭐",
                      products: _topRated,
                      onSeeAll: () {},
                    ),
                  ),

                  // Spacer at bottom
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
    );
  }
}
