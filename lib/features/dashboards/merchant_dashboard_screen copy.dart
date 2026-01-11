import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/models/user_model.dart';

// Services & Models
import 'package:linyora_project/features/dashboards/services/merchant_service.dart';
import 'package:linyora_project/features/dashboards/models/merchant_dashboard_model.dart';

// Screens
import 'package:linyora_project/features/dashboards/screens/verification_screen.dart';
import 'package:linyora_project/features/products/screens/merchant_products_screen.dart';
import 'package:linyora_project/features/dashboards/orders/screens/merchant_orders_screen.dart';
import 'package:linyora_project/features/dashboards/stories/screens/merchant_stories_screen.dart';
import 'package:linyora_project/features/subscriptions/screens/subscription_plans_screen.dart';

// Widgets
import 'widgets/agreement_modal.dart';
import 'widgets/stat_card.dart';
import 'widgets/sales_chart.dart';
import 'widgets/recent_orders_list.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // ============================================================
    // 1️⃣ منطق الأقفال (Lock Logic)
    // ============================================================

    // هل الحساب موثق؟
    final bool isVerified = user.verificationStatus == 'approved';

    // هل المستخدم مشترك؟
    final bool isSubscribed = user.isSubscribed;

    // هل لديه صلاحية الدروب شيبينج؟ (يجب أن يكون مشتركاً + الباقة تدعم الدروب شيبينج)
    final bool hasDropshippingAccess =
        isSubscribed && (user.subscription?.hasDropshippingAccess ?? false);

    // ============================================================
    // 2️⃣ تعريف القائمة مع حالة القفل (isLocked)
    // ============================================================
    final List<Map<String, dynamic>> allNavLinks = [
      {
        'title': 'لوحة التحكم',
        'icon': Icons.dashboard_outlined,
        'page': const _MerchantHomeView(),
        'show': true,
        'isLocked': false, // دائماً مفتوحة
      },
      {
        'title': 'توثيق الحساب',
        'icon': Icons.verified_user_outlined,
        'page': const VerificationScreen(),
        'show': !isVerified, // تختفي بعد التوثيق
        'isLocked': false,
      },
      {
        'title': 'إدارة المنتجات',
        'icon': Icons.inventory_2_outlined,
        'page': const MerchantProductsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل إذا لم يكن مشتركاً
      },
      {
        'title': 'الطلبات',
        'icon': Icons.shopping_bag_outlined,
        'page': const MerchantOrdersScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
      {
        'title': 'قصص المتجر',
        'icon': Icons.history_edu_outlined,
        'page': const MerchantStoriesScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
      {
        'title': 'الدروب شيبينج',
        'icon': Icons.cloud_download_outlined,
        'page': const Scaffold(body: Center(child: Text("الدروب شيبينج"))),
        'show': isVerified, // يظهر دائماً للموثقين
        'isLocked':
            !hasDropshippingAccess, // 🔒 مقفل إذا لم يكن لديه الصلاحية الخاصة
      },
      {
        'title': 'الشحن',
        'icon': Icons.local_shipping_outlined,
        'page': const Scaffold(body: Center(child: Text("الشحن"))),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
      {
        'title': 'المحفظة',
        'icon': Icons.account_balance_wallet_outlined,
        'page': const Scaffold(body: Center(child: Text("المحفظة"))),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
      {
        'title': 'الإعدادات',
        'icon': Icons.settings_outlined,
        'page': const Scaffold(body: Center(child: Text("الإعدادات"))),
        'show': true,
        'isLocked': false, // الإعدادات دائماً مفتوحة
      },
    ];

    // عنصر الاشتراك في القائمة (اختياري، للوصول السريع)
    if (isVerified) {
      allNavLinks.insert(5, {
        'title': isSubscribed ? 'تفاصيل اشتراكي' : 'اشترك الآن',
        'icon': isSubscribed ? Icons.credit_card : Icons.star_border,
        'page': const SubscriptionPlansScreen(),
        'show': true,
        'isLocked': false,
        'isSubscriptionAction': true, // علامة لتمييزه
      });
    }

    // تصفية العناصر المخفية (مثل التوثيق بعد الانتهاء منه)
    final visibleNavItems =
        allNavLinks.where((item) => item['show'] == true).toList();

    if (_currentIndex >= visibleNavItems.length) _currentIndex = 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          visibleNavItems[_currentIndex]['title'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () => setState(() {}),
            ),
        ],
      ),

      // ============================================================
      // 3️⃣ القائمة الجانبية (Drawer) مع القفل
      // ============================================================
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF43F5E), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    user.avatar != null ? NetworkImage(user.avatar!) : null,
                child:
                    user.avatar == null
                        ? Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Color(0xFF9333EA),
                          ),
                        )
                        : null,
              ),
              accountName: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Row(
                children: [
                  Flexible(
                    child: Text(
                      user.email ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 5),
                    const Icon(Icons.verified, color: Colors.white, size: 16),
                  ],
                  if (isSubscribed) ...[
                    const SizedBox(width: 5),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                  ],
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: visibleNavItems.length + 1,
                itemBuilder: (context, index) {
                  if (index == visibleNavItems.length) {
                    return ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap:
                          () async =>
                              await Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).logout(),
                    );
                  }

                  final item = visibleNavItems[index];
                  final bool isSelected = _currentIndex == index;
                  final bool isLocked = item['isLocked'] == true;

                  return ListTile(
                    leading: Icon(
                      item['icon'],
                      color:
                          isLocked
                              ? Colors.grey
                              : (isSelected
                                  ? const Color(0xFF9333EA)
                                  : Colors.grey[600]),
                    ),
                    title: Row(
                      children: [
                        Text(
                          item['title'],
                          style: TextStyle(
                            color:
                                isLocked
                                    ? Colors.grey
                                    : (isSelected
                                        ? const Color(0xFF9333EA)
                                        : Colors.grey[800]),
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        if (isLocked) ...[
                          const Spacer(),
                          const Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.purple.withOpacity(0.05),
                    onTap: () {
                      Navigator.pop(context); // إغلاق القائمة أولاً

                      if (isLocked) {
                        // ⛔️ إذا كان مقفلاً، وجهه للاشتراك
                        _showSubscriptionLockedDialog(context, item['title']);
                      } else {
                        // ✅ إذا كان مفتوحاً، انتقل للصفحة
                        if (item['isSubscriptionAction'] == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionPlansScreen(),
                            ),
                          );
                        } else {
                          setState(() => _currentIndex = index);
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: visibleNavItems[_currentIndex]['page'] as Widget,
    );
  }

  // نافذة تنبيه عند الضغط على عنصر مقفل
  void _showSubscriptionLockedDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("الميزة مغلقة 🔒"),
            content: Text(
              "عذراً، ميزة ($featureName) تتطلب اشتراكاً فعالاً للوصول إليها.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionPlansScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E),
                  foregroundColor: Colors.white,
                ),
                child: const Text("اشترك الآن"),
              ),
            ],
          ),
    );
  }
}

// -----------------------------------------------------------------------------
// ✅ محتوى الصفحة الرئيسية (بدون فرض الاشتراك، فقط الاتفاقية)
// -----------------------------------------------------------------------------

class _MerchantHomeView extends StatefulWidget {
  const _MerchantHomeView({Key? key}) : super(key: key);

  @override
  State<_MerchantHomeView> createState() => _MerchantHomeViewState();
}

class _MerchantHomeViewState extends State<_MerchantHomeView> {
  final MerchantService _merchantService = MerchantService();
  MerchantDashboardData? _data;
  bool _isLoading = true;
  String? _error;
  String _salesPeriod = 'week';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAgreementAndFetchData();
    });
  }

  // ✅ التحقق من الاتفاقية فقط، وعدم إجبار الاشتراك هنا
  Future<void> _checkAgreementAndFetchData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    if (user.hasAcceptedAgreement == false) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder:
            (context) => AgreementModal(
              agreementKey: "merchant_agreement",
              onAgreed: () async {
                await authProvider.refreshUser();
                if (mounted) _fetchDashboardData();
              },
            ),
      );
    } else {
      // ✅ المستخدم وافق على الشروط -> حمل البيانات مباشرة (سواء مشترك أو لا)
      _fetchDashboardData();
    }
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _merchantService.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (باقي كود عرض الـ Widgets كما هو دون تغيير)
    final user = Provider.of<AuthProvider>(context).user;
    final isVerified = user?.verificationStatus == 'approved';

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(child: Text("خطأ: $_error")); // تحسين بسيط للعرض

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isVerified)
            _buildVerificationAlert(user?.verificationStatus ?? 'pending'),
          const SizedBox(height: 16),
          _buildWelcomeCard(user?.name ?? 'التاجر'),
          const SizedBox(height: 16),
          if (_data != null) ...[
            _buildStatsGrid(_data!),
            const SizedBox(height: 24),
            // ... باقي العناصر (الرسم البياني والطلبات)
            SalesChart(
              data:
                  _salesPeriod == 'week'
                      ? _data!.weeklySales
                      : _data!.monthlySales,
              isWeekly: _salesPeriod == 'week',
            ),
            const SizedBox(height: 24),
            RecentOrdersList(orders: _data!.recentOrders, onViewAll: () {}),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  // --- Widgets المساعدة (نفس الكود السابق) ---
  Widget _buildPeriodButton(String label, String value) {
    // ... (نفس الكود السابق)
    return GestureDetector(
      onTap: () => setState(() => _salesPeriod = value),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          label,
          style: TextStyle(
            fontWeight:
                _salesPeriod == value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationAlert(String status) {
    // ... (نفس الكود السابق، مختصر هنا)
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.amber.shade50,
      child: Text("حالة التوثيق: $status"),
    );
  }

  Widget _buildWelcomeCard(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'مرحباً، $userName 👋',
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }

  Widget _buildStatsGrid(MerchantDashboardData data) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        StatCard(
          title: 'المبيعات',
          value: '${data.totalSales}',
          icon: Icons.attach_money,
        ),
        StatCard(
          title: 'المنتجات',
          value: '${data.activeProducts}',
          icon: Icons.inventory,
        ),
      ],
    );
  }
}
