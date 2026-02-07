import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/layout/main_layout_screen.dart';
import 'package:linyora_project/features/products/screens/main_prodects.dart';
import 'package:provider/provider.dart';

// --- Providers & Screens ---
import 'package:linyora_project/features/cart/providers/cart_provider.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/cart/screens/cart_screen.dart';
import 'package:linyora_project/features/categories/screens/categories_screen.dart';
import 'package:linyora_project/features/categories/screens/category_products_screen.dart';
import 'package:linyora_project/features/home/screens/notifications_screen.dart';

// --- Services & Models ---
import 'package:linyora_project/features/home/services/section_service.dart';
import 'package:linyora_project/features/home/services/home_service.dart';
import 'package:linyora_project/features/home/services/layout_service.dart'; // ✅ تأكد من وجود هذا الملف
import 'package:linyora_project/features/home/widgets/marquee_widget.dart';
import 'package:linyora_project/features/home/widgets/search_screen.dart';
import 'package:linyora_project/models/product_model.dart';
import 'package:linyora_project/models/section_model.dart';
import 'package:linyora_project/models/banner_model.dart';
import 'package:linyora_project/models/category_model.dart';
import 'package:linyora_project/models/top_user_model.dart';

// --- Widgets ---
import 'package:linyora_project/features/home/widgets/flash_sale_section.dart';
import 'package:linyora_project/features/home/widgets/horizontal_product_list.dart';
import 'package:linyora_project/features/stories/widgets/stories_section.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/section_display.dart';
import '../widgets/banner_video_player.dart';
import '../widgets/top_user_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. Services
  final HomeService _homeService = HomeService();
  final SectionService _sectionService = SectionService();
  final LayoutService _layoutService = LayoutService(); // ✅ خدمة التخطيط
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
  List<ProductModel> _linyoraPicks = []; // مختارات لينيورا
  List<ProductModel> _seasonStyle = [];

  // ✅ القائمة الرئيسية التي تتحكم في ترتيب الصفحة بالكامل
  List<HomeLayoutItem> _layoutItems = [];

  // 3. State Variables
  bool _isLoading = true;
  int _currentBannerIndex = 0;
  Timer? _sliderTimer;
  int _unreadNotificationsCount = 0;
  bool _isReorderingMode = false;

  // ✅ التحقق من الأدمن (تأكد أن roleId 1 هو الأدمن في الداتابيز لديك)
  bool get _isAdmin {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user != null && user.roleId == 1;
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

  Future<void> _updateUnreadCount() async {
    final notifications = await _homeService.getNotifications();
    if (mounted) {
      setState(
        () =>
            _unreadNotificationsCount =
                notifications.where((n) => !n.isRead).length,
      );
    }
  }

  Future<void> _fetchData() async {
    try {
      // 1. جلب البيانات الخام أولاً
      final results = await Future.wait([
        _homeService.getBanners(),
        _homeService.getCategories(),
        _sectionService.getActiveSections(),
        _homeService.getTopModels(),
        _homeService.getTopMerchants(),
        _homeService.getProductsByType('new'),
        _homeService.getProductsByType('best'),
        _homeService.getProductsByType('top'),
        _homeService.getProductsByType('best'), // 8 (مختارات لينيورا)
        _homeService.getProductsByType('new'),
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
          _linyoraPicks = results[8] as List<ProductModel>;
          _seasonStyle = results[9] as List<ProductModel>;
        });

        // 2. بعد توفر البيانات، نجلب الترتيب من السيرفر ونبني القائمة
        final layout = await _layoutService.getHomeLayout(_sections);

        setState(() {
          _layoutItems = layout;
          _isLoading = false;
        });

        if (_banners.isNotEmpty) _handleAutoPlay(0);
      }
    } catch (e) {
      debugPrint("Error loading home data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAutoPlay(int index) {
    _sliderTimer?.cancel();
    if (_banners.isNotEmpty && !_banners[index].isVideo) {
      _sliderTimer = Timer(const Duration(seconds: 5), () {
        _carouselController.nextPage();
      });
    }
  }

  // --- Logic for Reordering ---

  void _moveItemUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _layoutItems.removeAt(index);
        _layoutItems.insert(index - 1, item);
      });
    }
  }

  void _moveItemDown(int index) {
    if (index < _layoutItems.length - 1) {
      setState(() {
        final item = _layoutItems.removeAt(index);
        _layoutItems.insert(index + 1, item);
      });
    }
  }

  Future<void> _saveLayout() async {
    try {
      await _layoutService.saveLayoutOrder(_layoutItems);
      setState(() => _isReorderingMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ ترتيب الصفحة الرئيسية بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- UI Builder Methods ---

  // ✅ المصنع الذي يحول العنصر (Item) إلى ويدجت (Widget)
  Widget _mapLayoutItemToWidget(HomeLayoutItem item) {
    switch (item.type) {
      case HomeItemType.marquee:
        return const MarqueeWidget();
      case HomeItemType.stories:
        return const StoriesSection();
      case HomeItemType.banners:
        return _buildBannersSection();
      case HomeItemType.flashSale:
        return const FlashSaleSection();
      case HomeItemType.categories:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
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
              ),
            ),
            _buildCategoriesScroller(),
            _buildDivider(),
          ],
        );
      case HomeItemType.newArrivals:
        return Column(
          children: [
            HorizontalProductList(
              title: "وصل حديثاً 🆕",
              products: _newArrivals,
              // ✅ تفعيل زر عرض الكل
              onSeeAll: () => _navigateToViewAll("وصل حديثاً", "new"),
            ),
            _buildDivider(),
          ],
        );
      case HomeItemType.linyoraPicks:
        // إذا كانت القائمة فارغة نخفي القسم
        if (_linyoraPicks.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            HorizontalProductList(
              title: "مختارات لينيورا ✨",
              products: _linyoraPicks,
              // ✅ تفعيل زر عرض الكل (نمرر النوع picks)
              onSeeAll: () => _navigateToViewAll("مختارات لينيورا", "picks"),
            ),
            _buildDivider(),
          ],
        );

      case HomeItemType.seasonStyle:
        if (_seasonStyle.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            HorizontalProductList(
              title: "ستايل الموسم 🍂",
              products: _seasonStyle,
              // ✅ تفعيل زر عرض الكل (نمرر النوع season)
              onSeeAll: () => _navigateToViewAll("ستايل الموسم", "season"),
            ),
            _buildDivider(),
          ],
        );
      case HomeItemType.bestSellers:
        return Column(
          children: [
            HorizontalProductList(
              title: "الأكثر مبيعاً 🔥",
              products: _bestSellers,
              // ✅ تفعيل زر عرض الكل
              onSeeAll: () => _navigateToViewAll("الأكثر مبيعاً", "best"),
            ),
            _buildDivider(),
          ],
        );
      case HomeItemType.topRated:
        return Column(
          children: [
            HorizontalProductList(
              title: "الأعلى تقييماً ⭐",
              products: _topRated,
              // ✅ تفعيل زر عرض الكل
              onSeeAll: () => _navigateToViewAll("الأعلى تقييماً", "top"),
            ),
            _buildDivider(),
          ],
        );
      case HomeItemType.topModels:
        if (_topModels.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            // يمكنك توجيه هذا لصفحة العارضات
            _buildSectionTitleWrapper("أشهر العارضات ✨", () {}),
            _buildTopUsersList(_topModels, isModel: true),
            _buildDivider(),
          ],
        );
      case HomeItemType.topMerchants:
        if (_topMerchants.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            _buildSectionTitleWrapper("متاجر مميزة 🛍️", () {}),
            _buildTopUsersList(_topMerchants, isModel: false),
            _buildDivider(),
          ],
        );
      case HomeItemType.dynamicSection:
        if (item.data is SectionModel) {
          return Column(
            children: [
              SectionDisplay(section: item.data),
              Container(height: 8, color: Colors.grey[100]),
            ],
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  // ✅ دالة مساعدة للانتقال (عليك إنشاء هذه الشاشة أو استخدام شاشة المنتجات الموجودة لديك)
  void _navigateToViewAll(String title, String apiType) {
    // ✅ الطريقة الصحيحة (تفتح الهيكل الرئيسي وتحدد صفحة المنتجات)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => const MainLayoutScreen(
              initialIndex: 1,
            ), // رقم 1 هو ترتيب المنتجات
      ),
      (route) =>
          false, // هذا يمنع الرجوع للصفحة السابقة (اجعلها true إذا أردت السماح بالرجوع)
    );
  }

  // ✅ ودجت التغليف: تضيف أدوات التحكم فوق العنصر إذا كان وضع التعديل مفعلاً
  Widget _buildReorderableWrapper(int index, Widget child) {
    // إذا لم يكن أدمن أو الوضع غير مفعل، ارجع العنصر كما هو
    if (!_isReorderingMode || !_isAdmin) return child;

    // تحديد اسم العنصر للعرض
    String label = itemTypeToLabel(_layoutItems[index]);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.amber.shade300,
          width: 2,
        ), // حدود لتمييز العنصر
      ),
      child: Column(
        children: [
          // شريط التحكم العلوي
          Container(
            color: Colors.amber.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.drag_indicator, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_circle_up,
                    size: 28,
                    color: index > 0 ? Colors.blue : Colors.grey,
                  ),
                  onPressed: index > 0 ? () => _moveItemUp(index) : null,
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_circle_down,
                    size: 28,
                    color:
                        index < _layoutItems.length - 1
                            ? Colors.blue
                            : Colors.grey,
                  ),
                  onPressed:
                      index < _layoutItems.length - 1
                          ? () => _moveItemDown(index)
                          : null,
                ),
              ],
            ),
          ),
          // المحتوى
          child,
        ],
      ),
    );
  }

  String itemTypeToLabel(HomeLayoutItem item) {
    switch (item.type) {
      case HomeItemType.marquee:
        return "شريط الأخبار";
      case HomeItemType.stories:
        return "القصص (Stories)";
      case HomeItemType.banners:
        return "البنرات الإعلانية";
      case HomeItemType.flashSale:
        return "فلاش سيل";
      case HomeItemType.categories:
        return "الأقسام (Categories)";
      case HomeItemType.newArrivals:
        return "وصل حديثاً";
      case HomeItemType.bestSellers:
        return "الأكثر مبيعاً";
      case HomeItemType.topRated:
        return "الأعلى تقييماً";
      case HomeItemType.linyoraPicks:
        return "مختارات لينيورا";
      case HomeItemType.seasonStyle:
        return "ستايل الموسم";
      case HomeItemType.topModels:
        return "أشهر العارضات";
      case HomeItemType.topMerchants:
        return "متاجر مميزة";
      case HomeItemType.dynamicSection:
        return "قسم خاص: ${(item.data as SectionModel).title}";
      default:
        return item.id;
    }
  }

  // --- Standard Widgets Implementation ---

  Widget _buildAppBar() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isRealAdmin =
        authProvider.user != null && authProvider.user!.roleId == 1;

    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.grid_view_outlined, color: Colors.black),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => CategoriesScreen()),
            ),
      ),
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
          const Text(
            "L",
            style: TextStyle(
              color: Colors.pink,
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w900,
              fontSize: 30,
              letterSpacing: 2.0,
            ),
          ),
          if (isRealAdmin)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "ADMIN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        // ✅ زر التعديل للأدمن
        if (isRealAdmin)
          IconButton(
            tooltip: _isReorderingMode ? "حفظ الترتيب" : "تعديل ترتيب الصفحة",
            icon: CircleAvatar(
              radius: 18,
              backgroundColor:
                  _isReorderingMode ? Colors.green : Colors.grey[200],
              child: Icon(
                _isReorderingMode ? Icons.save : Icons.tune,
                color: _isReorderingMode ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
            onPressed: () {
              if (_isReorderingMode) {
                _saveLayout();
              } else {
                setState(() => _isReorderingMode = true);
              }
            },
          ),

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
                    builder: (c) => const NotificationsScreen(),
                  ),
                );
                _updateUnreadCount();
              },
            ),
            if (_unreadNotificationsCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  child: Center(
                    child: Text(
                      "$_unreadNotificationsCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),

        Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black,
                    size: 28,
                  ),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const CartScreen()),
                      ),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    top: 3,
                    right: 4,
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
                          "${cart.itemCount}",
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: Container(
          height: 70,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const SearchScreen()),
                ),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
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
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                    color: Colors.grey,
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
    if (_categories.isEmpty) return const SizedBox.shrink();
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    return Container(
      height: isTablet ? 140 : 120,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: CarouselSlider.builder(
        itemCount: _categories.length,
        options: CarouselOptions(
          height: isTablet ? 120 : 100,
          autoPlay: true,
          viewportFraction: isTablet ? 0.15 : 0.22,
          enableInfiniteScroll: true,
          padEnds: false,
        ),
        itemBuilder: (context, index, realIndex) {
          final category = _categories[index];
          final double circleSize = isTablet ? 80 : 65;
          final double fontSize = isTablet ? 14 : 12;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6.0),
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (c) => CategoryProductsScreen(
                            slug: category.slug,
                            categoryName: category.name,
                          ),
                    ),
                  ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey.shade300, width: 1),
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
    );
  }

  Widget _buildBannersSection() {
    if (_banners.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: CarouselSlider(
        carouselController: _carouselController,
        options: CarouselOptions(
          height: double.infinity,
          viewportFraction: 1.0,
          enlargeCenterPage: false,
          autoPlay: false,
          enableInfiniteScroll: true,
          scrollPhysics: const BouncingScrollPhysics(),
          onPageChanged: (index, reason) {
            setState(() => _currentBannerIndex = index);
            _handleAutoPlay(index);
          },
        ),
        items:
            _banners.asMap().entries.map((entry) {
              var banner = entry.value;
              bool isActive = entry.key == _currentBannerIndex;
              return Stack(
                fit: StackFit.expand,
                children: [
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
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder:
                            (_, __) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        errorWidget: (_, __, ___) => const Icon(Icons.error),
                      ),
                  _buildBannerOverlay(banner),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildBannerOverlay(BannerModel banner) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                banner.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                ),
              ),
              if (banner.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  banner.subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (banner.buttonText.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    // ✅ هنا التغيير لفتح الرابط الخارجي
                    onPressed: () => _launchExternalUrl(banner.link),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          banner.buttonText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios, size: 10),
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

  Future<void> _launchExternalUrl(String url) async {
    if (url.isEmpty) return;

    final Uri uri = Uri.parse(url);

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // يمكنك إظهار رسالة خطأ هنا للمستخدم
        print('Could not launch $url');
      }
    } catch (e) {
      print('Error launching url: $e');
    }
  }

  Widget _buildSectionTitleWrapper(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsersList(List<TopUserModel> users, {required bool isModel}) {
    if (users.isEmpty) return const SizedBox.shrink();

    // 1. حساب عرض الشاشة
    final double screenWidth = MediaQuery.of(context).size.width;

    // 2. عرض البطاقة الثابت + الهوامش (160 width + 20 margin horizontal)
    const double cardWidth = 180.0;

    // 3. حساب النسبة المطلوبة بدقة لتناسب حجم البطاقة
    double fraction = cardWidth / screenWidth;

    // تأكد أن النسبة لا تزيد عن 1 (لشاشات الهواتف الصغيرة جداً)
    if (fraction > 1.0) fraction = 1.0;

    return CarouselSlider.builder(
      itemCount: users.length,
      itemBuilder: (context, index, realIndex) {
        return TopUserCard(user: users[index], isModel: isModel);
      },
      options: CarouselOptions(
        height: 240,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,

        // ✅ التعديل هنا: استخدام النسبة المحسوبة ديناميكياً
        viewportFraction: fraction,

        // ✅ إضافة هذا السطر: لمنع توسيط البطاقة الأولى (يجعلها تبدأ من اليمين/اليسار)
        padEnds: false,

        enlargeCenterPage: false, // يفضل إلغاؤها في التابلت لتقليل الفراغات
        enableInfiniteScroll: true,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(height: 2, color: Colors.pink.withOpacity(0.1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  // ✅ بناء القائمة ديناميكياً باستخدام SliverList
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _layoutItems[index];
                      // تغليف كل عنصر بأدوات التحكم (للأدمن)
                      return _buildReorderableWrapper(
                        index,
                        _mapLayoutItemToWidget(item),
                      );
                    }, childCount: _layoutItems.length),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
    );
  }
}
