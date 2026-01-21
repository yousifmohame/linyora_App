import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:linyora_project/features/influencers/bank/screens/model_bank_settings_screen.dart';
import 'package:linyora_project/features/influencers/notifications/screens/notification_screen.dart';
import 'package:linyora_project/features/influencers/notifications/services/notifications_service.dart';
import 'package:linyora_project/features/influencers/offers/screens/model_offers_screen.dart';
import 'package:linyora_project/features/influencers/profile/screens/model_profile_settings.dart';
import 'package:linyora_project/features/influencers/requests/screens/model_requests_screen.dart';
import 'package:linyora_project/features/influencers/services/model_service.dart';
import 'package:linyora_project/features/influencers/stories/screens/stories_screen.dart';
import 'package:linyora_project/features/influencers/verification/screens/verification_screen.dart';
import 'package:linyora_project/features/models/analytics/screens/model_analytics_screen.dart';
import 'package:linyora_project/features/models/wallet/screens/model_wallet_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Providers & Services
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/models/models/model_dashboard_models.dart'; // استخدام نفس المودلز

// Screens
import 'package:linyora_project/features/chat/screens/chat_screen.dart';
import 'package:linyora_project/features/subscriptions/screens/subscription_plans_screen.dart';
import 'package:linyora_project/features/subscriptions/screens/my_subscription_screen.dart';
import 'package:linyora_project/features/settings/screens/settings_screen.dart';
import 'package:linyora_project/features/models/screens/agreement_model.dart'; // Modal Widget

class InfluencerDashboardScreen extends StatefulWidget {
  const InfluencerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<InfluencerDashboardScreen> createState() =>
      _InfluencerDashboardScreenState();
}

class _InfluencerDashboardScreenState extends State<InfluencerDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 🎨 ثيم الإنفلونسر (Tech/Social Vibe)
  final Color _primaryColor = const Color(0xFF4F46E5); // Indigo
  final Color _accentColor = const Color(0xFF06B6D4); // Cyan
  final Color _backgroundColor = const Color(0xFFF3F4F6);

  final NotificationsService _notificationsService = NotificationsService();
  int _unreadNotificationsCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    // ✅ 2. بدء جلب الإشعارات
    _updateUnreadCount();
    // تحديث كل 45 ثانية
    _notificationTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (mounted) _updateUnreadCount();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

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
      // ignore error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // منطق الأقفال
    final bool isVerified = user.verificationStatus == 'approved';
    final bool isSubscribed = user.isSubscribed;

    final Map<String, dynamic> subscriptionNavItem =
        isSubscribed
            ? {
              'title': 'باقتي الحالية',
              'icon': Icons.card_membership,
              'page': const MySubscriptionScreen(),
              'show': isVerified,
              'isLocked': false,
            }
            : {
              'title': 'ترقية الحساب',
              'icon': Icons.rocket_launch,
              'page': const SubscriptionPlansScreen(),
              'show': isVerified,
              'isLocked': false,
            };

    final List<Map<String, dynamic>> allNavLinks = [
      {
        'title': 'لوحة القيادة',
        'icon': Icons.grid_view_rounded,
        'page': const _InfluencerHomeView(),
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
        'title': 'عروضي',
        'icon': Icons.local_offer_outlined,
        'page': const InfluencerOffersScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'طلبات التعاون',
        'icon': Icons.handshake_outlined,
        'page': const InfluencerRequestsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'القصص (Stories)',
        'icon': Icons.amp_stories_outlined,
        'page': const InfluencerStoriesScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'التحليلات والأداء',
        'icon': Icons.insights_outlined,
        'page': const ModelAnalyticsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'المحفظة المالية',
        'icon': Icons.account_balance_wallet_outlined,
        'page': const ModelWalletScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'الرسائل',
        'icon': Icons.chat_bubble_outline,
        'page': ChatScreen(currentUserId: user.id),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      subscriptionNavItem,
      {
        'title': 'الحساب البنكي',
        'icon': Icons.account_balance_outlined,
        'page': const InfluencerBankSettingsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': 'الملف الشخصي',
        'icon': Icons.person_outline,
        'page': const InfluencerProfileSettingsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
    ];

    final visibleNavItems =
        allNavLinks.where((item) => item['show'] == true).toList();
    if (_currentIndex >= visibleNavItems.length) _currentIndex = 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          visibleNavItems[_currentIndex]['title'],
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.sort, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // زر الجرس
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none_outlined,
                      color: _primaryColor,
                      size: 28,
                    ),
                    onPressed: () async {
                      // ✅ الذهاب لصفحة الإشعارات
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const ModelNotificationsScreen(),
                        ),
                      );
                      // ✅ تحديث العداد عند العودة
                      _updateUnreadCount();
                    },
                  ),

                  // ✅ شارة العداد (Badge)
                  if (_unreadNotificationsCount > 0)
                    Positioned(
                      right: 6, // تعديل الموضع ليناسب أيقونة outlined
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red, // اللون الأحمر للتنبيه (قياسي)
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
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
      drawer: Drawer(
        elevation: 0,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, const Color(0xFF312E81)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _accentColor, width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                      user.avatar != null ? NetworkImage(user.avatar!) : null,
                  child:
                      user.avatar == null
                          ? Text(
                            user.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
              ),
              accountName: Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              accountEmail: Row(
                children: [
                  Flexible(
                    child: Text(
                      user.email ?? '',
                      style: TextStyle(color: Colors.indigo[100]),
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.verified,
                      color: Colors.cyanAccent,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visibleNavItems.length + 1,
                  separatorBuilder:
                      (ctx, i) => const Divider(height: 1, indent: 60),
                  itemBuilder: (context, index) {
                    if (index == visibleNavItems.length) {
                      return ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? _primaryColor.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item['icon'],
                          color:
                              isLocked
                                  ? Colors.grey
                                  : (isSelected
                                      ? _primaryColor
                                      : Colors.grey[600]),
                          size: 22,
                        ),
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
                                          ? _primaryColor
                                          : const Color(0xFF374151)),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (isLocked) ...[
                            const Spacer(),
                            const Icon(
                              Icons.lock_person_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ],
                      ),
                      tileColor: isSelected ? Colors.grey[50] : null,
                      onTap: () {
                        Navigator.pop(context);
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.workspace_premium, color: _primaryColor),
                const SizedBox(width: 8),
                const Text("ميزة حصرية"),
              ],
            ),
            content: Text(
              "ميزة ($featureName) متاحة فقط للمشتركين. قم بترقية حسابك للوصول إلى أدوات احترافية.",
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "ليس الآن",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPlansScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text("ترقية الآن"),
              ),
            ],
          ),
    );
  }
}

// =============================================================================
// ✅ محتوى الصفحة الرئيسية (Real Data)
// =============================================================================

class _InfluencerHomeView extends StatefulWidget {
  const _InfluencerHomeView({Key? key}) : super(key: key);

  @override
  State<_InfluencerHomeView> createState() => _InfluencerHomeViewState();
}

class _InfluencerHomeViewState extends State<_InfluencerHomeView> {
  final InfluencerService _service = InfluencerService();

  DashboardStats? _stats;
  List<RecentActivity> _activities = [];
  bool _isLoading = true;
  String? _error;

  final Color _indigo = const Color(0xFF4F46E5);
  final Color _cyan = const Color(0xFF06B6D4);
  final Color _darkBlue = const Color(0xFF1E1B4B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAgreementAndFetchData();
    });
  }

  Future<void> _checkAgreementAndFetchData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    if (user.hasAcceptedAgreement == false) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => WillPopScope(
              onWillPop: () async => false,
              child: AgreementModal(
                agreementKey: "influencer_agreement",
                onAgreed: () async {
                  await _service.acceptAgreement();
                  await authProvider.refreshUser();
                  if (mounted) _fetchDashboardData();
                },
              ),
            ),
      );
    } else {
      _fetchDashboardData();
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ✅ جلب بيانات حقيقية من السيرفس
      final results = await Future.wait([
        _service.getDashboardStats(),
        _service.getRecentActivity(),
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
      return Center(child: CircularProgressIndicator(color: _indigo));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('حدث خطأ في تحميل البيانات'),
            ElevatedButton(
              onPressed: _fetchDashboardData,
              child: Text('محاولة مجدداً'),
            ),
          ],
        ),
      );
    }

    final user = Provider.of<AuthProvider>(context).user;

    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cyan.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          top: 100,
          left: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _indigo.withOpacity(0.05),
            ),
          ),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernWelcomeCard(user?.name ?? 'المؤثر'),
              const SizedBox(height: 24),

              if (_stats != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        "الرصيد الكلي",
                        "${_stats!.totalEarnings}",
                        "ر.س",
                        Icons.wallet,
                        _indigo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        "طلبات نشطة",
                        "${_stats!.pendingRequests}",
                        "طلب",
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        "أرباح الشهر",
                        "${_stats!.monthlyEarnings}",
                        "ر.س",
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        "المشاهدات",
                        "${_stats!.profileViews}",
                        "",
                        Icons.visibility,
                        _cyan,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              const Text(
                "نشاطك الأخير",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children:
                      _activities.isEmpty
                          ? [
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "لا توجد نشاطات",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ]
                          : _activities
                              .map((act) => _buildTimelineItem(act))
                              .toList(),
                ),
              ),

              const SizedBox(height: 24),
              if (_stats != null)
                _buildPerformanceCard((_stats!.responseRate ?? 0) / 100),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernWelcomeCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_darkBlue, _indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _indigo.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "أهلاً بعودتك،",
                style: TextStyle(
                  color: _cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Level: Pro Influencer",
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_graph, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: " ($unit)",
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(RecentActivity act) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: _cyan, shape: BoxShape.circle),
              ),
              Container(width: 2, height: 30, color: Colors.grey[200]),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  act.time,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(double rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _darkBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "معدل الاستجابة",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "تفاعلك مع الطلبات ممتاز!",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: rate,
                  backgroundColor: Colors.white24,
                  color: _cyan,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _cyan, width: 2),
            ),
            child: Text(
              "${(rate * 100).toInt()}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
