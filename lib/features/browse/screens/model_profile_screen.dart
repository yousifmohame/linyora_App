import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/auth/services/auth_service.dart';
import 'package:linyora_project/features/chat/screens/chat_screen.dart';
import 'package:linyora_project/features/chat/services/chat_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/model_profile_details.dart';
import '../services/browse_service.dart';
import 'package:provider/provider.dart';

import '../../subscriptions/screens/payment_webview_screen.dart'; // استخدمنا شاشة الدفع السابقة

class ModelProfileScreen extends StatefulWidget {
  final int modelId;
  const ModelProfileScreen({Key? key, required this.modelId}) : super(key: key);

  @override
  State<ModelProfileScreen> createState() => _ModelProfileScreenState();
}

class _ModelProfileScreenState extends State<ModelProfileScreen>
    with SingleTickerProviderStateMixin {
  final BrowseService _service = BrowseService();
  final ChatService _chatService = ChatService();
  late TabController _tabController;
  final AuthService _authService = AuthService.instance;

  ModelFullProfile? _profile;
  List<Offer> _offers = [];
  List<ServicePackage> _packages = [];
  List<MerchantProduct> _merchantProducts = [];

  bool _isLoading = true;

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
          // 1. البروفايل
          _profile = ModelFullProfile.fromJson(data['profile']);

          // 2. العروض
          if (data['offers'] != null) {
            _offers =
                (data['offers'] as List).map((e) => Offer.fromJson(e)).toList();
          }

          // 3. الباقات (مع حماية إضافية)
          _packages = []; // تصفير القائمة
          if (data['packages'] != null) {
            try {
              _packages =
                  (data['packages'] as List)
                      .map((e) => ServicePackage.fromJson(e))
                      .toList();
              print("✅ UI Success: Loaded ${_packages.length} packages");

              // فحص هل الباقات تحتوي على مستويات (Tiers)؟
              for (var p in _packages) {
                print("Package: ${p.title} has ${p.tiers.length} tiers");
              }
            } catch (e) {
              print("❌ UI Error parsing packages: $e");
            }
          }

          _merchantProducts = products;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      print("❌ Fatal Error in _fetchData: $e");
      print(s);
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء عرض البيانات: $e')));
    }
  }

  Future<void> _startConversation() async {
    final user = _authService.currentUser;

    // 1. التحقق من تسجيل الدخول
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول لبدء محادثة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2. إظهار مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. استدعاء السيرفس (باستخدام الرابط الصحيح الآن)
      final conversationId = await _chatService.createConversation(
        _profile!.id,
      );

      Navigator.pop(context); // إغلاق التحميل

      if (conversationId != null) {
        if (mounted) {
          // 4. الانتقال لشاشة الشات
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatScreen(
                    initialActiveConversationId: conversationId,
                    currentUserId: user.id,
                  ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل بدء المحادثة، حاول مرة أخرى')),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  Future<void> _handleRequest({Offer? offer, PackageTier? tier}) async {
    if (_merchantProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون لديك منتجات لتتمكن من الطلب'),
        ),
      );
      return;
    }

    // إظهار Dialog لاختيار المنتج
    MerchantProduct? selectedProduct;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("اختر المنتج للترويج"),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _merchantProducts.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final p = _merchantProducts[index];
                      return ListTile(
                        leading:
                            p.imageUrl != null
                                ? CachedNetworkImage(
                                  imageUrl: p.imageUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                )
                                : const Icon(Icons.shopping_bag),
                        title: Text(p.name),
                        subtitle: Text(p.category ?? ''),
                        onTap: () {
                          selectedProduct = p;
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
    );

    if (selectedProduct == null) return;

    // بدء الدفع
    try {
      final url = await _service.createAgreementSession(
        modelId: _profile!.id,
        productId: selectedProduct!.id.toString(),
        offerId: offer?.id,
        packageTierId: tier?.id,
      );

      if (url != null && mounted) {
        // فتح شاشة الدفع
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(checkoutUrl: url),
          ),
        );

        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم إرسال الطلب بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل عملية الدفع'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF43F5E)),
        ),
      );
    }

    if (_profile == null) {
      return const Scaffold(body: Center(child: Text("المستخدم غير موجود")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2), // خلفية زهرية فاتحة جداً
      body: CustomScrollView(
        slivers: [
          // 1. Header with Gradient
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: const Color(0xFFF43F5E),
            flexibleSpace: FlexibleSpaceBar(background: _buildProfileHeader()),
            actions: [
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            ],
          ),

          // 2. Stats Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildStatsGrid(),
            ),
          ),

          // 3. Social & Languages
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSocialLinks(),
                  const SizedBox(height: 16),
                  _buildLanguages(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 4. Tabs (Portfolio, Packages, Offers)
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFF43F5E),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFF43F5E),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "المعرض", icon: Icon(Icons.camera_alt_outlined)),
                  Tab(text: "الباقات", icon: Icon(Icons.shopping_bag_outlined)),
                  Tab(text: "العروض", icon: Icon(Icons.local_offer_outlined)),
                ],
              ),
            ),
            pinned: true,
          ),

          // 5. Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPortfolioTab(),
                _buildPackagesTab(),
                _buildOffersTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: ElevatedButton(
          onPressed: _startConversation,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF43F5E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline),
              SizedBox(width: 8),
              Text(
                "ابدأ محادثة",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          _profile!.profilePictureUrl != null
                              ? CachedNetworkImageProvider(
                                _profile!.profilePictureUrl!,
                              )
                              : null,
                      child:
                          _profile!.profilePictureUrl == null
                              ? Text(_profile!.name[0])
                              : null,
                    ),
                  ),
                  if (_profile!.isVerified)
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _profile!.roleId == 3 ? "عارضة أزياء" : "مؤثرة",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_profile!.stats.rating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _profile!.stats.rating.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_profile!.location != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _profile!.location!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _profile!.bio,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children:
                _profile!.categories
                    .map(
                      (c) => Chip(
                        label: Text(
                          c,
                          style: const TextStyle(
                            color: Color(0xFF9333EA),
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  // --- Stats ---
  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "الإحصائيات",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                "المتابعين",
                _profile!.stats.followers,
                Icons.group,
                Colors.pink,
              ),
              _buildStatItem(
                "تفاعل",
                _profile!.stats.engagement,
                Icons.favorite,
                Colors.purple,
              ),
              _buildStatItem(
                "سرعة الرد",
                _profile!.avgResponseTime,
                Icons.timer,
                Colors.blue,
              ),
              _buildStatItem(
                "اكتمال",
                _profile!.completionRate,
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  // --- Social & Langs ---
  Widget _buildSocialLinks() {
    if (_profile!.socialLinks == null) return const SizedBox();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_profile!.socialLinks!.instagram != null)
          _socialBtn(FontAwesomeIcons.instagram, Colors.purple, "Instagram"),
        const SizedBox(width: 12),
        if (_profile!.socialLinks!.twitter != null)
          _socialBtn(FontAwesomeIcons.twitter, Colors.blue, "Twitter"),
        const SizedBox(width: 12),
        if (_profile!.socialLinks!.facebook != null)
          _socialBtn(
            FontAwesomeIcons.facebook,
            Colors.blue.shade800,
            "Facebook",
          ),
      ],
    );
  }

  Widget _socialBtn(IconData icon, Color color, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguages() {
    if (_profile!.languages.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("اللغات", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                _profile!.languages
                    .map(
                      (l) => Chip(
                        label: Text(l, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey.shade100,
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  // --- Tabs Content ---
  Widget _buildPortfolioTab() {
    if (_profile!.portfolio.isEmpty) {
      return _buildEmptyState(
        "لا توجد صور في المعرض",
        Icons.image_not_supported,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _profile!.portfolio.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: _profile!.portfolio[index],
            fit: BoxFit.cover,
            placeholder: (c, u) => Container(color: Colors.grey.shade200),
          ),
        );
      },
    );
  }

  Widget _buildPackagesTab() {
    if (_packages.isEmpty)
      return _buildEmptyState(
        "لا توجد باقات متاحة",
        Icons.inventory_2_outlined,
      );
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _packages.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final pkg = _packages[index];
        return Card(
          elevation: 4,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF43F5E), Color(0xFF9333EA)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Text(
                  pkg.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children:
                      pkg.tiers
                          .map(
                            (tier) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.pink.shade100),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tier.tierName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.pink.shade800,
                                        ),
                                      ),
                                      Text(
                                        "${tier.price} ر.س",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  ...tier.features.map(
                                    (f) => Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          f,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          () => _handleRequest(tier: tier),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF43F5E,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text("طلب الباقة"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOffersTab() {
    if (_offers.isEmpty)
      return _buildEmptyState("لا توجد عروض خاصة", Icons.local_offer_outlined);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _offers.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final offer = _offers[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.pink.shade100),
            boxShadow: [
              BoxShadow(color: Colors.pink.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.pink.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.description,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        offer.type,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.pink.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    "${offer.price} ر.س",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFFF43F5E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _handleRequest(offer: offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF43F5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text("طلب"),
                  ),
                ],
              ),
            ],
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
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Helper for Sticky TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
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
    return Container(color: const Color(0xFFFFF1F2), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
