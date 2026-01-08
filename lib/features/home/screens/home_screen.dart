import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/cart/providers/cart_provider.dart';
import 'package:linyora_project/features/cart/screens/cart_screen.dart';
import 'package:linyora_project/features/categories/screens/categories_screen.dart';
import 'package:linyora_project/features/categories/screens/category_products_screen.dart';
import 'package:linyora_project/features/home/screens/notifications_screen.dart';
// --- Services & Models ---
import 'package:linyora_project/features/home/services/section_service.dart';
import 'package:linyora_project/features/home/services/home_service.dart';
import 'package:linyora_project/features/home/widgets/marquee_widget.dart';
import 'package:linyora_project/features/home/widgets/search_screen.dart';
import 'package:linyora_project/models/product_model.dart';
import 'package:linyora_project/models/section_model.dart';
import 'package:linyora_project/models/banner_model.dart';
import 'package:linyora_project/models/category_model.dart';
import 'package:linyora_project/models/top_user_model.dart';
import 'package:provider/provider.dart';

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

  // متغير لحفظ عدد الإشعارات غير المقروءة
  int _unreadNotificationsCount = 0;

  // دالة لحساب الإشعارات غير المقروءة
  Future<void> _updateUnreadCount() async {
    // نجلب الإشعارات (التي أضفناها للسيرفس سابقاً)
    final notifications = await _homeService.getNotifications();
    if (mounted) {
      setState(() {
        // نحسب فقط العناصر التي فيها isRead == false
        _unreadNotificationsCount =
            notifications.where((n) => !n.isRead).length;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _updateUnreadCount();

    Future.microtask(() => Provider.of<CartProvider>(context, listen: false));
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
        icon: const Icon(Icons.grid_view_outlined, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CategoriesScreen()),
          );
        },
      ),

      // 3. العنوان (اسم التطبيق)
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "INOYRA",
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 2),
          Stack(
            alignment: Alignment.topRight,
            children: [
              const Text(
                "L",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Playfair Display',
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  height: 0.8,
                ),
              ),
              Transform.translate(
                offset: const Offset(4, -4),
                child: const Icon(
                  Icons.star,
                  color: Colors.pinkAccent,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
      // centerTitle: true, // تمت إزالته ليكون الشعار في البداية
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
                _updateUnreadCount();
              },
            ),
            // يظهر فقط إذا كان هناك إشعارات غير مقروءة
            if (_unreadNotificationsCount > 0)
              Positioned(
                top: 8, // تعديل بسيط للموقع ليكون فوق الأيقونة
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4), // مساحة داخلية للنص
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  // تحديد حد أدنى للعرض ليكون دائرياً حتى مع الأرقام الصغيرة
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  child: Center(
                    child: Text(
                      // إذا كان العدد أكبر من 9 نعرض 9+
                      _unreadNotificationsCount > 9
                          ? "9+"
                          : "$_unreadNotificationsCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1, // لضبط توسيط النص عمودياً
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // أيقونة السلة (مهمة جداً)
        // أيقونة السلة (تم التعديل لتكون حقيقية)
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons
                        .shopping_cart_outlined, // يفضل outlined ليتناسق مع التنبيهات
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed: () {
                    // ✅ الانتقال لصفحة السلة
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),

                // ✅ عرض الشارة فقط إذا كان هناك منتجات
                if (cart.itemCount > 0)
                  Positioned(
                    top: 3,
                    right: 4, // تعديل الموضع قليلاً
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          "${cart.itemCount}", // ✅ العدد الحقيقي
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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
              // ==========================================
              // التعديل هنا: الانتقال لشاشة البحث
              // ==========================================
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
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

  Widget _buildCategoriesScroller() {
    if (_categories.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    // 1. حساب عرض الشاشة لتحديد القيم المتجاوبة
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    return SliverToBoxAdapter(
      child: Container(
        height: isTablet ? 140 : 120, // زيادة الارتفاع قليلاً في التابلت
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: CarouselSlider.builder(
          itemCount: _categories.length,
          options: CarouselOptions(
            height: isTablet ? 120 : 100, // ارتفاع العنصر
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,

            // 2. التعديل الجوهري هنا:
            // في الموبايل: 0.22 (يعرض ~4.5 عنصر)
            // في التابلت: 0.15 (يعرض ~6.5 عنصر) لأن الشاشة أعرض
            viewportFraction: isTablet ? 0.15 : 0.22,

            enableInfiniteScroll: true,
            padEnds: false,
          ),
          itemBuilder: (context, index, realIndex) {
            final category = _categories[index];

            // تكبير العناصر قليلاً في التابلت
            final double circleSize = isTablet ? 80 : 65;
            final double fontSize = isTablet ? 14 : 12;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6.0),
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
                    // دائرة الصورة (متجاوبة)
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            category.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                  imageUrl: category.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (_, __) => const Padding(
                                        padding: EdgeInsets.all(15.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                  errorWidget:
                                      (_, __, ___) => const Icon(
                                        Icons.category,
                                        color: Colors.grey,
                                      ),
                                )
                                : const Icon(
                                  Icons.grid_view_rounded,
                                  color: Colors.grey,
                                ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // اسم القسم (متجاوب)
                    SizedBox(
                      width: circleSize + 10,
                      child: Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
    );
  }

  Widget _buildBannersSection() {
    if (_banners.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      // 1. حذفنا الـ Padding هنا ليأخذ العرض كاملاً
      child: SizedBox(
        // جعلنا الارتفاع يعتمد على حجم الشاشة ليكون متجاوباً (مثلاً 35% من طول الشاشة)
        height: MediaQuery.of(context).size.height * 0.35,
        child: CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: double.infinity, // ليملأ الـ SizedBox الأب
            // ============================================
            // أهم التغييرات لجعل البانر يملأ الشاشة:
            // ============================================
            viewportFraction: 1.0, // يأخذ 100% من عرض الشاشة
            enlargeCenterPage: false, // إلغاء تأثير التكبير والتبعيد
            autoPlay: false, // تحكم يدوي (أو true حسب رغبتك)
            enableInfiniteScroll: true,
            scrollPhysics: const BouncingScrollPhysics(), // حركة ناعمة
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
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. الخلفية (صورة أو فيديو)
                        banner.isVideo
                            ? BannerVideoPlayer(
                              videoUrl: banner.imageUrl,
                              isActive: isActive,
                              onVideoFinished: () {
                                if (isActive) _carouselController.nextPage();
                              },
                            )
                            : CachedNetworkImage(
                              imageUrl: banner.imageUrl,
                              fit: BoxFit.cover, // يغطي المساحة بالكامل
                              width: double.infinity,
                              placeholder:
                                  (_, __) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              errorWidget:
                                  (_, __, ___) => const Icon(Icons.error),
                            ),

                        // 2. التظليل والنص (Overlay)
                        _buildBannerOverlay(banner),
                      ],
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
                      Navigator.pushNamed(context, banner.link);
                      // print("Navigating to: ${banner.link}");
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

  // دالة مساعدة تعرض قسماً واحداً بناءً على رقمه (Index)
  Widget _buildSectionSafe(int index) {
    // إذا كان الاندكس غير موجود (مثلاً لدينا 3 أقسام فقط وطلبنا القسم رقم 5)، نرجع فراغ
    if (index >= _sections.length) return const SizedBox.shrink();

    return Column(
      children: [
        // عرض القسم
        SectionDisplay(section: _sections[index]),
        // الفاصل تحته
        Container(height: 8, color: Colors.grey[100]),
      ],
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

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'تسوق حسب الفئة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          height: 1.3,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),

                  _buildCategoriesScroller(),

                  _buildDivider(),

                  // 5. Categories Header & Grid
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
                      // داخل SliverList delegate
                      (context, index) {
                        final sectionWidget = SectionDisplay(
                          section: _sections[index],
                        );
                        Widget? injectedWidget;

                        // حساب نقطة المنتصف (تجاهل الكسور باستخدام ~/ )
                        // مثلاً لو العدد 15، المنتصف سيكون عند الاندكس 7
                        int middleIndex = _sections.length ~/ 2;

                        // 1. بعد القسم الأول مباشرة
                        if (index == middleIndex) {
                          injectedWidget = HorizontalProductList(
                            title: "قد يعجبك أيضاً ❤️",
                            products: _bestSellers,
                            onSeeAll: () {},
                          );
                        }

                        return Column(
                          children: [
                            sectionWidget,
                            Container(height: 8, color: Colors.grey[100]),
                            if (injectedWidget != null) ...[
                              injectedWidget,
                              Container(height: 8, color: Colors.grey[100]),
                            ],
                          ],
                        );
                      },
                      // ======================================================
                      // هذا الرقم يضمن عرض جميع الأقسام الـ 15 القادمة من الباك اند
                      // ======================================================
                      childCount: _sections.length,
                    ),
                  ),

                  // --- نضع تحته: الأكثر مبيعاً ---
                  SliverToBoxAdapter(
                    child: HorizontalProductList(
                      title: "الأكثر مبيعاً 🔥",
                      products: _bestSellers,
                      onSeeAll: () {},
                    ),
                  ),
                  _buildDivider(),

                  // --- القسم الديناميكي الثالث (رقم 2) ---
                  SliverToBoxAdapter(child: _buildSectionSafe(2)),

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
