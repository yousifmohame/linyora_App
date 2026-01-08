import 'package:flutter/material.dart';
import 'package:linyora_project/features/dashboards/orders/screens/merchant_orders_screen.dart';
import 'package:linyora_project/features/products/screens/merchant_products_screen.dart';
import 'package:provider/provider.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/dashboards/models/merchant_dashboard_model.dart';
import 'package:linyora_project/features/dashboards/services/merchant_service.dart';
import 'package:linyora_project/features/dashboards/screens/verification_screen.dart';

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

  // قائمة الصفحات
  final List<Widget> _pages = [
    const _MerchantHomeView(), // 0: الرئيسية (الإحصائيات)
    const VerificationScreen(), // 1: التوثيق
    const MerchantProductsScreen(), // 2: المنتجات
    const MerchantOrdersScreen(),
    const Scaffold(body: Center(child: Text("القصص (قريباً)"))), // 4
    const Scaffold(body: Center(child: Text("الشحن (قريباً)"))), // 5
    const Scaffold(body: Center(child: Text("المحفظة (قريباً)"))), // 6
    const Scaffold(body: Center(child: Text("الإعدادات (قريباً)"))), // 7
  ];

  // عناوين الصفحات
  final List<String> _titles = [
    'لوحة التحكم',
    'توثيق الحساب',
    'إدارة المنتجات',
    'الطلبات',
    'قصص المتجر',
    'الشحن والتوصيل',
    'المحفظة',
    'الإعدادات',
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isVerified = user?.verificationStatus == 'approved';

    // تعريف عناصر القائمة الجانبية
    final List<Map<String, dynamic>> navItems = [
      {
        'title': 'الرئيسية',
        'icon': Icons.dashboard_outlined,
        'index': 0,
        'show': true,
      },
      {
        'title': 'التوثيق',
        'icon': Icons.verified_user_outlined,
        'index': 1,
        'show': !isVerified,
      },
      {
        'title': 'المنتجات',
        'icon': Icons.inventory_2_outlined,
        'index': 2,
        'show': isVerified,
      },
      {
        'title': 'الطلبات',
        'icon': Icons.shopping_bag_outlined,
        'index': 3,
        'show': isVerified,
      },
      {
        'title': 'القصص',
        'icon': Icons.history_edu_outlined,
        'index': 4,
        'show': isVerified,
      },
      {
        'title': 'الشحن',
        'icon': Icons.local_shipping_outlined,
        'index': 5,
        'show': isVerified,
      },
      {
        'title': 'المحفظة',
        'icon': Icons.account_balance_wallet_outlined,
        'index': 6,
        'show': isVerified,
      },
      {
        'title': 'الإعدادات',
        'icon': Icons.settings_outlined,
        'index': 7,
        'show': true,
      },
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
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
          // إخفاء زر التحديث إذا لم نكن في الصفحة الرئيسية
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                // نستخدم EventBus أو Controller لتحديث الابن،
                // ولكن هنا سنقوم بإعادة بناء الصفحة ببساطة
                setState(() {});
              },
            ),
        ],
      ),

      // ✅ القائمة الجانبية (Drawer)
      drawer: Drawer(
        child: Column(
          children: [
            // رأس القائمة (Header)
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
                    user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                child:
                    user?.avatar == null
                        ? Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'M',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Color(0xFF9333EA),
                          ),
                        )
                        : null,
              ),
              accountName: Text(
                user?.name ?? 'التاجر',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Row(
                children: [
                  Text(user?.email ?? ''),
                  const SizedBox(width: 8),
                  if (isVerified)
                    const Icon(Icons.verified, color: Colors.white, size: 16),
                ],
              ),
            ),

            // عناصر القائمة
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...navItems.where((item) => item['show'] == true).map((item) {
                    final bool isSelected = _currentIndex == item['index'];
                    return ListTile(
                      leading: Icon(
                        item['icon'],
                        color:
                            isSelected
                                ? const Color(0xFF9333EA)
                                : Colors.grey[600],
                      ),
                      title: Text(
                        item['title'],
                        style: TextStyle(
                          color:
                              isSelected
                                  ? const Color(0xFF9333EA)
                                  : Colors.grey[800],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: Colors.purple.withOpacity(0.05),
                      onTap: () {
                        setState(() => _currentIndex = item['index']);
                        Navigator.pop(context); // إغلاق القائمة
                      },
                    );
                  }).toList(),

                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      await Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).logout();
                      // سيتم التوجيه تلقائياً عبر AuthDispatcher في main.dart
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ✅ جسم الصفحة (يتغير حسب الاختيار)
      body: _pages[_currentIndex],
    );
  }
}

// -----------------------------------------------------------------------------
// ✅ محتوى الصفحة الرئيسية (تم فصله ليكون الكود أنظف)
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkUserStatusAndFetchData(),
    );
  }

  Future<void> _checkUserStatusAndFetchData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    if (user.hasAcceptedAgreement == false) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AgreementModal(
              onAgreed: () async {
                await authProvider.refreshUser();
                if (mounted) _fetchDashboardData();
              },
            ),
      );
    } else {
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
    final user = Provider.of<AuthProvider>(context).user;
    final isVerified = user?.verificationStatus == 'approved';

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('حدث خطأ: $_error'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchDashboardData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "تحليل المبيعات",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodButton('أسبوعي', 'week'),
                      _buildPeriodButton('شهري', 'month'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SalesChart(
              data:
                  _salesPeriod == 'week'
                      ? _data!.weeklySales
                      : _data!.monthlySales,
              isWeekly: _salesPeriod == 'week',
            ),
            const SizedBox(height: 24),
            RecentOrdersList(
              orders: _data!.recentOrders,
              onViewAll: () {
                // يمكن الوصول للأب لتغيير الصفحة أو استخدام Navigator
                // context.findAncestorStateOfType<_MerchantDashboardScreenState>()?.setState(() => _currentIndex = 3);
              },
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _salesPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _salesPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                    ),
                  ]
                  : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationAlert(String status) {
    Color bgColor;
    Color textColor;
    String title;
    String message;

    switch (status) {
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        title = 'تم رفض التوثيق';
        message = 'يرجى مراجعة البيانات وإعادة المحاولة.';
        break;
      case 'not_submitted':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        title = 'مطلوب التوثيق';
        message = 'يرجى إكمال بيانات توثيق التاجر للبدء في البيع.';
        break;
      default:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        title = 'قيد المراجعة';
        message = 'جاري مراجعة بياناتك، سيتم تفعيل حسابك قريباً.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(message, style: TextStyle(fontSize: 12, color: textColor)),
              ],
            ),
          ),
          if (status == 'not_submitted' || status == 'rejected')
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VerificationScreen(),
                  ),
                );
              },
              child: Text('بدء التوثيق', style: TextStyle(color: textColor)),
            ),
        ],
      ),
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً، $userName 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'إليك نظرة سريعة على أداء متجرك اليوم.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(MerchantDashboardData data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          title: 'إجمالي المبيعات',
          value: '${data.totalSales.toStringAsFixed(2)} ر.س',
          icon: Icons.attach_money,
        ),
        StatCard(
          title: 'الطلبات الجديدة',
          value: '+${data.recentOrders.length}',
          icon: Icons.shopping_cart_outlined,
        ),
        StatCard(
          title: 'المنتجات النشطة',
          value: '${data.activeProducts} / ${data.totalProducts}',
          icon: Icons.inventory_2_outlined,
        ),
        StatCard(
          title: 'التقييم العام',
          value: data.averageRating.toStringAsFixed(1),
          description: 'من ${data.totalReviews} تقييم',
          icon: Icons.star_border,
        ),
        StatCard(
          title: 'المشاهدات الشهرية',
          value: data.monthlyViews.toString(),
          icon: Icons.visibility_outlined,
        ),
      ],
    );
  }
}
