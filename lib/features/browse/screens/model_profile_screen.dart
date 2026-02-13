import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ 1. استيراد المكتبة
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/auth/services/auth_service.dart';
import 'package:linyora_project/features/chat/screens/chat_screen.dart';
import 'package:linyora_project/features/chat/services/chat_service.dart';
import '../models/model_profile_details.dart';
import '../services/browse_service.dart';
import '../../subscriptions/screens/payment_Services.dart';

class ModelProfileScreen extends StatefulWidget {
  final int modelId;
  const ModelProfileScreen({Key? key, required this.modelId}) : super(key: key);

  @override
  State<ModelProfileScreen> createState() => _ModelProfileScreenState();
}

class _ModelProfileScreenState extends State<ModelProfileScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final BrowseService _service = BrowseService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService.instance;
  final PaymentService _paymentService = PaymentService();

  // Controllers
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Data
  ModelFullProfile? _profile;
  List<Offer> _offers = [];
  List<ServicePackage> _packages = [];
  List<MerchantProduct> _merchantProducts = [];
  bool _isLoading = true;

  // Modern Color Palette
  final Color _accentColor = const Color(0xFFE11D48); // Rose-600
  final Color _darkText = const Color(0xFF1F2937);
  final Color _lightText = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _service.getModelDetails(widget.modelId);
      final products = await _service.getMerchantProducts();

      if (mounted) {
        setState(() {
          _profile = ModelFullProfile.fromJson(data['profile']);
          if (data['offers'] != null) {
            _offers =
                (data['offers'] as List).map((e) => Offer.fromJson(e)).toList();
          }
          if (data['packages'] != null) {
            _packages =
                (data['packages'] as List)
                    .map((e) => ServicePackage.fromJson(e))
                    .toList();
          }
          _merchantProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ 2. دالة فتح الروابط الخارجية
  Future<void> _launchSocialLink(String? url) async {
    if (url == null || url.isEmpty) {
      _showSnack('الرابط غير متوفر', isError: true);
      return;
    }

    // التأكد من أن الرابط يبدأ بـ http/https
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showSnack('تعذر فتح الرابط', isError: true);
      }
    } catch (e) {
      _showSnack('حدث خطأ أثناء فتح الرابط', isError: true);
    }
  }

  // --- Logic Methods ---
  Future<void> _startConversation() async {
    final user = _authService.currentUser;
    if (user == null) {
      _showSnack('يجب تسجيل الدخول أولاً', isError: true);
      return;
    }
    _showLoadingDialog();
    try {
      final conversationId = await _chatService.createConversation(
        _profile!.id,
      );
      Navigator.pop(context);
      if (conversationId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatListScreen(
                  initialActiveConversationId: conversationId,
                  currentUserId: user.id,
                ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showSnack('حدث خطأ، حاول مرة أخرى', isError: true);
    }
  }

  Future<void> _handleRequest({Offer? offer, PackageTier? tier}) async {
    if (_merchantProducts.isEmpty) {
      _showSnack('يجب أن يكون لديك منتجات لتتمكن من الطلب', isError: true);
      return;
    }
    MerchantProduct? selectedProduct;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => _buildProductSelector((p) {
            selectedProduct = p;
            Navigator.pop(context);
          }),
    );

    if (selectedProduct == null) return;

    await _paymentService.payForAgreement(
      context: context,
      modelId: _profile!.id,
      productId: selectedProduct!.id,
      packageTierId: tier?.id,
      offerId: offer?.id,
      onSuccess: () => _showSnack('✅ تم إرسال الطلب بنجاح!', isError: false),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );
  }

  // --- Main Build ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profile == null)
      return const Scaffold(body: Center(child: Text("غير موجود")));

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildHeaderContent()),
            SliverPersistentHeader(
              delegate: _ModernTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: _accentColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _accentColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  tabs: const [
                    Tab(text: "المعرض"),
                    Tab(text: "الباقات"),
                    Tab(text: "العروض"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPortfolioTab(),
            _buildPackagesTab(),
            _buildOffersTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: const BackButton(color: Colors.black),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            _profile!.profilePictureUrl != null
                ? CachedNetworkImage(
                  imageUrl: _profile!.profilePictureUrl!,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.3),
                  colorBlendMode: BlendMode.darken,
                )
                : Container(color: Colors.grey.shade300),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Hero(
                    tag: 'profile_${_profile!.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            _profile!.profilePictureUrl != null
                                ? CachedNetworkImageProvider(
                                  _profile!.profilePictureUrl!,
                                )
                                : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _profile!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_profile!.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _profile!.roleId == 3 ? "عارضة ازياء" : "منشئة محتوي",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 3. تحديث قسم الهيدر لعرض الأزرار الحقيقية
  Widget _buildHeaderContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _profile!.bio,
            style: TextStyle(color: _lightText, height: 1.5, fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // عرض أزرار التواصل فقط إذا كانت الروابط موجودة
          if (_profile!.socialLinks != null)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_profile!.socialLinks!.instagram != null &&
                    _profile!.socialLinks!.instagram!.isNotEmpty)
                  _buildSocialChip(
                    icon: FontAwesomeIcons.instagram,
                    label: "Instagram",
                    onTap:
                        () =>
                            _launchSocialLink(_profile!.socialLinks!.instagram),
                  ),

                if (_profile!.socialLinks!.twitter != null &&
                    _profile!.socialLinks!.twitter!.isNotEmpty)
                  _buildSocialChip(
                    icon: FontAwesomeIcons.twitter,
                    label: "Twitter",
                    onTap:
                        () => _launchSocialLink(_profile!.socialLinks!.twitter),
                  ),

                if (_profile!.socialLinks!.facebook != null &&
                    _profile!.socialLinks!.facebook!.isNotEmpty)
                  _buildSocialChip(
                    icon: FontAwesomeIcons.facebook,
                    label: "Facebook",
                    onTap:
                        () =>
                            _launchSocialLink(_profile!.socialLinks!.facebook),
                  ),

                if (_profile!.socialLinks!.tiktok != null &&
                    _profile!.socialLinks!.tiktok!.isNotEmpty)
                  _buildSocialChip(
                    icon: FontAwesomeIcons.tiktok,
                    label: "TikTok",
                    onTap:
                        () => _launchSocialLink(_profile!.socialLinks!.tiktok),
                  ),

                if (_profile!.socialLinks!.snapchat != null &&
                    _profile!.socialLinks!.snapchat!.isNotEmpty)
                  _buildSocialChip(
                    icon: FontAwesomeIcons.snapchat,
                    label: "Snapchat",
                    onTap:
                        () =>
                            _launchSocialLink(_profile!.socialLinks!.snapchat),
                  ),
              ],
            ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildModernStat(_profile!.stats.followers, "المتابعون"),
                Container(height: 30, width: 1, color: Colors.grey.shade300),
                _buildModernStat(
                  _profile!.stats.rating.toString(),
                  "التقييم ⭐",
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade300),
                _buildModernStat(_profile!.stats.engagement, "التفاعل"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: _darkText,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: _lightText, fontSize: 11)),
      ],
    );
  }

  // ✅ 4. تحديث الزر ليقبل أمر الضغط (onTap)
  Widget _buildSocialChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _darkText),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: _darkText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioTab() {
    if (_profile!.portfolio.isEmpty) {
      return _buildEmptyState(
        "لا توجد صور في المعرض",
        Icons.photo_library_outlined,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.8,
      ),
      itemCount: _profile!.portfolio.length,
      itemBuilder: (context, index) {
        final imgUrl = _profile!.portfolio[index];
        return GestureDetector(
          onTap: () => _openFullScreenGallery(context, index),
          child: Hero(
            tag: 'portfolio_$imgUrl',
            child: CachedNetworkImage(
              imageUrl: imgUrl,
              fit: BoxFit.cover,
              placeholder: (c, u) => Container(color: Colors.grey.shade100),
              errorWidget: (c, u, e) => const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }

  void _openFullScreenGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FullScreenGallery(
              images: _profile!.portfolio,
              initialIndex: initialIndex,
            ),
      ),
    );
  }

  Widget _buildPackagesTab() {
    if (_packages.isEmpty)
      return _buildEmptyState("لا توجد باقات", Icons.inventory_2_outlined);

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _packages.length,
      separatorBuilder: (c, i) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final pkg = _packages[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                pkg.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
            ),
            ...pkg.tiers
                .map(
                  (tier) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tier.tierName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _darkText,
                                ),
                              ),
                              Text(
                                "${tier.price} ر.س",
                                style: TextStyle(
                                  color: _accentColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              ...tier.features.map(
                                (f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          f,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _darkText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => _handleRequest(tier: tier),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    "اختيار الباقة",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildOffersTab() {
    if (_offers.isEmpty)
      return _buildEmptyState(
        "لا توجد عروض حالياً",
        Icons.local_offer_outlined,
      );

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _offers.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final offer = _offers[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        offer.type,
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "${offer.price} ر.س",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: _darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  offer.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.description,
                  style: TextStyle(color: _lightText, fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _handleRequest(offer: offer),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _accentColor),
                      foregroundColor: _accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("طلب العرض"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startConversation,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              label: const Text("محادثة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector(Function(MerchantProduct) onSelect) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "اختر منتج",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _merchantProducts.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final p = _merchantProducts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        p.imageUrl != null
                            ? CachedNetworkImage(
                              imageUrl: p.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : Container(
                              color: Colors.grey.shade100,
                              width: 50,
                              height: 50,
                              child: const Icon(Icons.image),
                            ),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => onSelect(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: 'portfolio_${widget.images[index]}',
                child: CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.contain,
                  placeholder:
                      (c, u) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModernTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _ModernTabBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_ModernTabBarDelegate oldDelegate) => false;
}
