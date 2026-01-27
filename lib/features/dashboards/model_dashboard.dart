import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:linyora_project/features/models/analytics/screens/model_analytics_screen.dart';
import 'package:linyora_project/features/models/bank/screens/model_bank_settings_screen.dart';
import 'package:linyora_project/features/models/chat/screens/chat_screen.dart';
import 'package:linyora_project/features/models/notifications/screens/notification_screen.dart';
import 'package:linyora_project/features/models/notifications/services/notifications_service.dart';
import 'package:linyora_project/features/models/offers/screens/model_offers_screen.dart';
import 'package:linyora_project/features/models/profile/screens/model_profile_settings.dart';
import 'package:linyora_project/features/models/reels/screens/model_reels_screen.dart';
import 'package:linyora_project/features/models/requests/screens/model_requests_screen.dart';
import 'package:linyora_project/features/models/stories/screens/stories_screen.dart';
import 'package:linyora_project/features/models/verification/screens/verification_screen.dart';
import 'package:linyora_project/features/models/wallet/screens/model_wallet_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Providers & Models
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/models/models/model_dashboard_models.dart';
import 'package:linyora_project/features/models/services/model_service.dart';

// Screens (Imports assumed based on project structure)
import 'package:linyora_project/features/models/screens/agreement_model.dart'; // Modal Widget
import 'package:linyora_project/features/subscriptions/screens/subscription_plans_screen.dart';
import 'package:linyora_project/features/subscriptions/screens/my_subscription_screen.dart';
import 'package:linyora_project/features/settings/screens/settings_screen.dart';

class ModelDashboardScreen extends StatefulWidget {
  const ModelDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ModelDashboardScreen> createState() => _ModelDashboardScreenState();
}

class _ModelDashboardScreenState extends State<ModelDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // الألوان الخاصة بالمودل
  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  final NotificationsService _notificationsService = NotificationsService();
  int _unreadNotificationsCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    // ✅ بدء جلب الإشعارات عند فتح التطبيق
    _updateUnreadCount();
    // ✅ تحديث كل 45 ثانية
    _notificationTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (mounted) _updateUnreadCount();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  // ✅ دالة التحديث
  Future<void> _updateUnreadCount() async {
    try {
      final notifications = await _notificationsService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadNotificationsCount =
              notifications.where((n) => !n.isRead).length;
        });
      }
    } catch (e) {
      // تجاهل الأخطاء الصامتة
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام Provider للحصول على تحديثات المستخدم لحظياً
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ============================================================
    // 1️⃣ منطق الأقفال (Lock Logic)
    // ============================================================
    final bool isVerified = user.verificationStatus == 'approved';
    final bool isSubscribed =
        user.isSubscribed; // افترضنا وجود هذا الحقل في User Model

    // عنصر الاشتراك في القائمة (ديناميكي)
    final Map<String, dynamic> subscriptionNavItem =
        isSubscribed
            ? {
              'title': 'اشتراكي',
              'icon': Icons.credit_card,
              'page': const MySubscriptionScreen(), // شاشة تفاصيل الاشتراك
              'show': isVerified,
              'isLocked': false,
            }
            : {
              'title': 'ترقية الحساب',
              'icon': Icons.star_border,
              'page': const SubscriptionPlansScreen(), // شاشة الباقات
              'show': isVerified,
              'isLocked': false,
            };

    // ============================================================
    // 2️⃣ تعريف القائمة
    // ============================================================
    final List<Map<String, dynamic>> allNavLinks = [
      {
        'title': 'الرئيسية',
        'icon': Icons.dashboard_outlined,
        'page': const _ModelHomeView(),
        'show': true,
        'isLocked': false,
      },
      {
        'title': 'توثيق الحساب',
        'icon': Icons.verified_user_outlined,
        'page': const VerificationScreen(),
        'show': !isVerified, // يختفي بعد التوثيق
        'isLocked': false,
      },
      {
        'title': 'العروض',
        'icon': Icons.shopping_bag_outlined,
        'page': ModelOffersScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل لغير المشتركين
      },
      {
        'title': 'الريلز',
        'icon': Icons.video_call_outlined,
        'page': const ModelReelsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'الطلبات',
        'icon': Icons.handshake_outlined,
        'page': ModelRequestsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
      {
        'title': 'القصص',
        'icon': Icons.image_outlined,
        'page': StoriesScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
      {
        'title': 'التحليلات',
        'icon': Icons.bar_chart_outlined,
        'page': ModelAnalyticsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
      {
        'title': 'المحفظة',
        'icon': Icons.account_balance_wallet_outlined,
        'page': ModelWalletScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
      {
        'title': 'المحادثات',
        'icon': Icons.message_outlined,
        'page': ChatScreen(currentUserId: user.id),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
      subscriptionNavItem, // زر الاشتراك المتغير
      {
        'title': 'التفاصيل البنكيه',
        'icon': Icons.money,
        'page': ModelBankSettingsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
      {
        'title': 'الملف الشخصي',
        'icon': Icons.person_outline,
        'page': ModelProfileSettingsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed, // 🔒 مقفل
      },
    ];

    // تصفية العناصر الظاهرة فقط
    final visibleNavItems =
        allNavLinks.where((item) => item['show'] == true).toList();

    // حماية المؤشر من الخروج عن النطاق
    if (_currentIndex >= visibleNavItems.length) _currentIndex = 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),

      // --- AppBar ---
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
          // ✅ زر الإشعارات يعمل الآن لأن المتغير _unreadNotificationsCount موجود هنا
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: _roseColor,
                      size: 28,
                    ),
                    onPressed: () async {
                      // عند الضغط ننتقل للشاشة وننتظر العودة
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const ModelNotificationsScreen(),
                        ),
                      );
                      // عند العودة نحدث العداد
                      _updateUnreadCount();
                    },
                  ),
                  if (_unreadNotificationsCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _purpleColor,
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
                                ? "9+"
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
            ),
        ],
      ),

      // --- Drawer (Sidebar) ---
      drawer: Drawer(
        child: Column(
          children: [
            // رأس القائمة (Gradient Rose/Purple)
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_roseColor, _purpleColor],
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
                          user.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            color: _purpleColor,
                            fontWeight: FontWeight.bold,
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

            // عناصر القائمة
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: visibleNavItems.length + 1,
                itemBuilder: (context, index) {
                  // زر تسجيل الخروج في النهاية
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
                              : (isSelected ? _purpleColor : Colors.grey[600]),
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
                                        ? _purpleColor
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
                      Navigator.pop(context); // إغلاق القائمة

                      if (isLocked) {
                        _showSubscriptionLockedDialog(context, item['title']);
                      } else {
                        setState(() => _currentIndex = index);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // --- Body ---
      body: visibleNavItems[_currentIndex]['page'] as Widget,
    );
  }

  // نافذة القفل
  void _showSubscriptionLockedDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.lock, color: _roseColor),
                const SizedBox(width: 8),
                const Text("الميزة مغلقة"),
              ],
            ),
            content: Text(
              "عذراً، ميزة ($featureName) متاحة فقط للمشترين في الباقات المميزة.",
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // الانتقال لصفحة الاشتراك
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPlansScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purpleColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text("ترقية الحساب"),
              ),
            ],
          ),
    );
  }
}

// =============================================================================
// ✅ محتوى الصفحة الرئيسية للمودل (الإحصائيات والنشاط)
// =============================================================================

class _ModelHomeView extends StatefulWidget {
  const _ModelHomeView({Key? key}) : super(key: key);

  @override
  State<_ModelHomeView> createState() => _ModelHomeViewState();
}

class _ModelHomeViewState extends State<_ModelHomeView> {
  final ModelService _modelService = ModelService();
  DashboardStats? _stats;
  List<RecentActivity> _activities = [];
  bool _isLoading = true;
  String? _error;

  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAgreementAndFetchData();
    });
  }

  // التحقق من الاتفاقية
  Future<void> _checkAgreementAndFetchData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 🔄 1. خطوة جديدة: تحديث بيانات المستخدم من السيرفر لضمان دقة الحالة
    try {
      await authProvider.refreshUser();
    } catch (e) {
      debugPrint("Failed to refresh user data: $e");
      // نستمر حتى لو فشل التحديث (اعتماداً على الكاش)
    }

    // 2. قراءة المستخدم بعد التحديث
    final user = authProvider.user;

    if (user == null) return;

    // 3. الآن التحقق دقيق
    if (user.hasAcceptedAgreement == false) {
      // إظهار الاتفاقية الإجبارية
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder:
            (context) => WillPopScope(
              onWillPop: () async => false,
              child: AgreementModal(
                // تأكد من تمرير المفتاح الصحيح هنا إذا كان المودال يطلبه (مثلاً "model_agreement")
                onAgreed: () async {
                  await _modelService.acceptAgreement();
                  await authProvider
                      .refreshUser(); // تحديث مرة أخرى بعد الموافقة
                  if (mounted) {
                    // Navigator.pop(context); // قد تحتاج لإغلاق المودال يدوياً هنا
                    _fetchDashboardData();
                  }
                },
              ),
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
      final results = await Future.wait([
        _modelService.getDashboardStats(),
        _modelService.getRecentActivity(),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as DashboardStats;
        _activities = results[1] as List<RecentActivity>;
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
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade50.withOpacity(0.3),
              Colors.purple.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('خطأ: $_error'),
            ElevatedButton(
              onPressed: _fetchDashboardData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final user = Provider.of<AuthProvider>(context).user;

    return Stack(
      children: [
        // الخلفية الجمالية
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.shade50.withOpacity(0.3),
                  Colors.purple.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(
          top: -50,
          right: -50,
          child: _buildBlurBlob(Colors.pink.shade200),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: _buildBlurBlob(Colors.purple.shade200),
        ),

        // المحتوى
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة الترحيب
              _buildWelcomeCard(user?.name ?? 'المودل'),

              const SizedBox(height: 20),

              // شبكة الإحصائيات
              if (_stats != null)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard(
                      "إجمالي الأرباح",
                      "${_stats!.totalEarnings} ر.س",
                      Icons.attach_money,
                      Colors.green,
                    ),
                    _buildStatCard(
                      "أرباح الشهر",
                      "${_stats!.monthlyEarnings} ر.س",
                      Icons.trending_up,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      "اتفاقيات",
                      "${_stats!.completedAgreements}",
                      Icons.check_circle_outline,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      "قيد الانتظار",
                      "${_stats!.pendingRequests}",
                      Icons.access_time,
                      Colors.orange,
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // النشاط الأخير
              _buildSectionCard(
                "النشاط الأخير",
                Icons.history,
                _purpleColor,
                Column(
                  children:
                      _activities.isEmpty
                          ? [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text("لا توجد نشاطات حديثة"),
                            ),
                          ]
                          : _activities
                              .take(5)
                              .map((act) => _buildActivityItem(act))
                              .toList(),
                ),
              ),

              const SizedBox(height: 24),

              // الأداء
              _buildSectionCard(
                "الأداء",
                Icons.trending_up,
                _roseColor,
                Column(
                  children: [
                    _buildPerformanceMetric(
                      "معدل الرد",
                      (_stats?.responseRate ?? 0) / 100,
                    ),
                    const SizedBox(height: 12),
                    _buildPerformanceMetric("إكمال الطلبات", 0.95),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  // --- Widgets مساعدة ---
  Widget _buildWelcomeCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_roseColor, _purpleColor]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _purpleColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "مرحباً، $name 👋",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "إليك ملخص أداء حسابك اليوم.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    Widget content,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity act) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[100],
            radius: 18,
            child: const Icon(
              Icons.notifications,
              size: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  act.time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, double value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text("${(value * 100).toInt()}%"),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[200],
          color: _purpleColor,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
