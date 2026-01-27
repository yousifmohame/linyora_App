import 'package:flutter/material.dart';
import 'package:linyora_project/features/agreements/screens/merchant_agreements_screen.dart';
import 'package:linyora_project/features/bank/screens/bank_settings_screen.dart';
import 'package:linyora_project/features/browse/screens/browse_models_screen.dart';
import 'package:linyora_project/features/chat/screens/chat_screen.dart';
import 'package:linyora_project/features/dashboards/MyStore/my_store_screen.dart';
import 'package:linyora_project/features/dropshipping/screens/merchant_dropshipping_screen.dart';
import 'package:linyora_project/features/settings/screens/settings_screen.dart';
import 'package:linyora_project/features/shipping/screens/merchant_shipping_screen.dart';
import 'package:linyora_project/features/subscriptions/screens/my_subscription_screen.dart';
import 'package:linyora_project/features/wallet/screens/merchant_wallet_screen.dart';
// ✅ 1. استيراد شاشة الإشعارات
import 'package:linyora_project/features/home/screens/notifications_screen.dart';
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

  // ✅ 2. متغيرات الإشعارات
  int _unreadNotificationsCount = 0;
  // سنستخدم MerchantService لجلب الإشعارات (تأكد من إضافة دالة getNotifications فيه)
  final MerchantService _merchantService = MerchantService();

  @override
  void initState() {
    super.initState();
    // ✅ 3. جلب الإشعارات عند البدء
    _fetchUnreadNotifications();
  }

  // ✅ 4. دالة جلب عدد الإشعارات غير المقروءة
  Future<void> _fetchUnreadNotifications() async {
    try {
      // نفترض أن دالة getNotifications موجودة في MerchantService وتعيد List<NotificationModel>
      // إذا لم تكن موجودة، يجب إضافتها لتستدعي '/api/notifications'
      final notifications = await _merchantService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationsCount =
              notifications.where((n) => !n.isRead).length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // ============================================================
    // 1️⃣ منطق الأقفال (Lock Logic)
    // ============================================================

    final bool isVerified = user.verificationStatus == 'approved';
    final bool isSubscribed = user.isSubscribed;
    final bool hasDropshippingAccess =
        isSubscribed && (user.subscription?.hasDropshippingAccess ?? false);

    final Map<String, dynamic> subscriptionNavItem =
        isSubscribed
            ? {
              'title': 'اشتراكي',
              'icon': Icons.credit_card,
              'page': const MySubscriptionScreen(),
              'show': isVerified,
            }
            : {
              'title': 'اشترك الآن',
              'icon': Icons.star_border,
              'page': const SubscriptionPlansScreen(),
              'show': isVerified,
            };

    final List<Map<String, dynamic>> allNavLinks = [
      {
        'title': 'لوحة التحكم',
        'icon': Icons.dashboard_outlined,
        'page': const _MerchantHomeView(),
        'show': true,
        'isLocked': false,
      },
      {
        'title': 'توثيق الحساب',
        'icon': Icons.verified_user_outlined,
        'page': const VerificationScreen(),
        'show': !isVerified,
        'isLocked': false,
      },
      {
        'title': 'إدارة المنتجات',
        'icon': Icons.inventory_2_outlined,
        'page': const MerchantProductsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'الطلبات',
        'icon': Icons.shopping_bag_outlined,
        'page': const MerchantOrdersScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'معاينه المتجر',
        'icon': Icons.shopping_bag_outlined,
        'page': const MyStoreScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'قصص المتجر',
        'icon': Icons.history_edu_outlined,
        'page': const MerchantStoriesScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'العارضات و المؤثرات',
        'icon': Icons.history_edu_outlined,
        'page': const BrowseModelsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'المحادثات',
        'icon': Icons.history_edu_outlined,
        'page': ChatScreen(currentUserId: user.id),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'الإتفاقيات',
        'icon': Icons.history_edu_outlined,
        'page': MerchantAgreementsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'المعلومات البنكيه',
        'icon': Icons.history_edu_outlined,
        'page': BankSettingsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'الدروب شيبينج',
        'icon': Icons.cloud_download_outlined,
        'page': const MerchantDropshippingScreen(),
        'show': isVerified,
        'isLocked': !hasDropshippingAccess,
      },
      subscriptionNavItem,
      {
        'title': 'الشحن',
        'icon': Icons.local_shipping_outlined,
        'page': const MerchantShippingScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'المحفظة',
        'icon': Icons.account_balance_wallet_outlined,
        'page': const MerchantWalletScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'الإعدادات',
        'icon': Icons.settings_outlined,
        'page': const SettingsScreen(),
        'show': true,
        'isLocked': false,
      },
    ];

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
        // ✅ 5. إضافة زر الإشعارات وزر التحديث
        actions: [
          // زر الإشعارات
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                  size: 28,
                ),
                onPressed: () async {
                  // الذهاب لصفحة الإشعارات
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                  // تحديث العدد عند العودة
                  _fetchUnreadNotifications();
                },
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotificationsCount > 9
                            ? "+9"
                            : "$_unreadNotificationsCount",
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

          // زر التحديث (فقط في لوحة التحكم الرئيسية)
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                setState(() {});
                _fetchUnreadNotifications(); // تحديث الإشعارات أيضاً
              },
            ),

          const SizedBox(width: 8),
        ],
      ),

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
                      Navigator.pop(context);

                      if (isLocked) {
                        _showSubscriptionLockedDialog(context, item['title']);
                      } else {
                        if (item['title'] == 'اشترك الآن' ||
                            item['title'] == 'اشتراكي') {
                          // التعامل مع عنصر الاشتراك المخصص
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => item['page']),
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

    // 🔄 1. خطوة جديدة: إجبار التطبيق على تحديث بيانات المستخدم من السيرفر أولاً
    try {
      await authProvider.refreshUser();
    } catch (e) {
      debugPrint("Warning: Failed to refresh user data: $e");
      // في حال فشل التحديث (مثلاً لا يوجد إنترنت)، سنعتمد على البيانات المحلية الحالية
    }

    // 2. الآن نقرأ بيانات المستخدم (بعد أن تم تحديثها من السيرفر)
    final user = authProvider.user;

    if (user == null) return;

    // 3. التحقق الآن يتم بناءً على أحدث بيانات من قاعدة البيانات
    if (user.hasAcceptedAgreement == false) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder:
            (context) => AgreementModal(
              agreementKey: "merchant_agreement",
              onAgreed: () async {
                // عند الموافقة، نحدث البيانات مرة أخرى للتأكيد
                await authProvider.refreshUser();
                if (mounted) {
                  // نغلق المودال يدوياً هنا لأنه داخل showDialog
                  // (ملاحظة: AgreementModal عادة يغلق نفسه، لكن للتأكد)
                  // Navigator.of(context).pop();

                  _fetchDashboardData();
                }
              },
            ),
      );
    } else {
      // ✅ المستخدم وافق مسبقاً (والبيانات محدثة) -> حمل البيانات
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
            Text('حدث خطأ: $_error', textAlign: TextAlign.center),
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
                // يمكن إضافة منطق لفتح تاب الطلبات
              },
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  // --- Widgets المساعدة (نفس الكود السابق) ---
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
