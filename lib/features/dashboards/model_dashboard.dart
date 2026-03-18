import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

// ✅ 1. استيراد الترجمة ומزود اللغة
import 'package:linyora_project/l10n/app_localizations.dart';
import 'package:linyora_project/features/shared/providers/locale_provider.dart';

import 'package:linyora_project/features/chat/screens/chat_screen.dart';
import 'package:linyora_project/features/layout/main_layout_screen.dart';
import 'package:linyora_project/features/models/analytics/screens/model_analytics_screen.dart';
import 'package:linyora_project/features/models/bank/screens/model_bank_settings_screen.dart';
import 'package:linyora_project/features/models/notifications/screens/notification_screen.dart';
import 'package:linyora_project/features/models/notifications/services/notifications_service.dart';
import 'package:linyora_project/features/models/offers/screens/model_offers_screen.dart';
import 'package:linyora_project/features/models/profile/screens/model_profile_settings.dart';
import 'package:linyora_project/features/models/reels/screens/model_reels_screen.dart';
import 'package:linyora_project/features/models/requests/screens/model_requests_screen.dart';
import 'package:linyora_project/features/models/stories/screens/stories_screen.dart';
import 'package:linyora_project/features/models/verification/screens/verification_screen.dart';
import 'package:linyora_project/features/public_profiles/screens/model_profile_screen.dart';
import 'package:linyora_project/features/shared/wallet/screens/wallet_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Providers & Models
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/models/models/model_dashboard_models.dart';
import 'package:linyora_project/features/models/services/model_service.dart';

// Screens
import 'package:linyora_project/features/models/screens/agreement_model.dart';
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

  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  final NotificationsService _notificationsService = NotificationsService();
  int _unreadNotificationsCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _updateUnreadCount();
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
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isVerified = user.verificationStatus == 'approved';
    final bool isSubscribed = user.isSubscribed;

    final Map<String, dynamic> subscriptionNavItem =
        isSubscribed
            ? {
              'title': l10n.mySubscription, // ✅ مترجم
              'icon': Icons.credit_card,
              'page': const MySubscriptionScreen(),
              'show': isVerified,
              'isLocked': false,
            }
            : {
              'title': l10n.upgradeAccount, // ✅ مترجم (سابقاً)
              'icon': Icons.star_border,
              'page': const SubscriptionPlansScreen(),
              'show': isVerified,
              'isLocked': false,
            };

    final List<Map<String, dynamic>> allNavLinks = [
      {
        'title': l10n.homeTab, // ✅ مترجم
        'icon': Icons.dashboard_outlined,
        'page': const _ModelHomeView(),
        'show': true,
        'isLocked': false,
      },
      {
        'title': l10n.accountVerification, // ✅ مترجم (سابقاً)
        'icon': Icons.verified_user_outlined,
        'page': const VerificationScreen(),
        'show': !isVerified,
        'isLocked': false,
      },
      {
        'title': l10n.offersTab, // ✅ مترجم
        'icon': Icons.shopping_bag_outlined,
        'page': const ModelOffersScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.reels, // ✅ مترجم (سابقاً)
        'icon': Icons.video_call_outlined,
        'page': const ModelReelsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.requestsTab, // ✅ مترجم
        'icon': Icons.handshake_outlined,
        'page': const ModelRequestsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.stories, // ✅ مترجم (سابقاً)
        'icon': Icons.image_outlined,
        'page': const StoriesScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.analyticsTitle, // ✅ مترجم (سابقاً)
        'icon': Icons.bar_chart_outlined,
        'page': const ModelAnalyticsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.financialWallet, // ✅ مترجم (سابقاً)
        'icon': Icons.account_balance_wallet_outlined,
        'page': const WalletScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.conversationsTitle, // ✅ مترجم (سابقاً)
        'icon': Icons.message_outlined,
        'page': ChatListScreen(currentUserId: user.id),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      subscriptionNavItem,
      {
        'title': l10n.bankDetailsTitle, // ✅ مترجم (سابقاً)
        'icon': Icons.money,
        'page': const ModelBankSettingsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.profile, // ✅ مترجم (سابقاً)
        'icon': Icons.person_outline,
        'page': const ModelProfileSettingsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
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
        actions: [
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
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const ModelNotificationsScreen(),
                        ),
                      );
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

      drawer: Drawer(
        child: Column(
          children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isVerified || isSubscribed) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (isVerified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.verified,
                                    color: Colors.blueAccent,
                                    size: 14,
                                  ),
                                ),
                              if (isSubscribed)
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ModelProfileScreen(
                                  modelId: user.id.toString(),
                                ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.previewBtn,
                            style: const TextStyle(fontSize: 14),
                          ), // ✅ مترجم (سابقاً)
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ✅✅✅ زر تغيير اللغة المضاف أعلى القائمة ✅✅✅
                  ListTile(
                    leading: Icon(Icons.language, color: Colors.orange),
                    title: Text(
                      l10n.changeLanguageLabel, // ✅ مترجم
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Provider.of<LocaleProvider>(
                        context,
                        listen: false,
                      ).toggleLocale();
                      Navigator.pop(context); // إغلاق القائمة الجانبية
                    },
                  ),
                  const Divider(height: 1, indent: 60),

                  // عرض عناصر القائمة الحركية
                  ...List.generate(visibleNavItems.length, (index) {
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
                                    ? _purpleColor
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
                        Navigator.pop(context);
                        if (isLocked) {
                          _showSubscriptionLockedDialog(
                            context,
                            item['title'],
                            l10n,
                          ); // ✅ تمرير l10n
                        } else {
                          setState(() => _currentIndex = index);
                        }
                      },
                    );
                  }),

                  const Divider(),

                  // زر تسجيل الخروج
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      l10n.logout, // ✅ مترجم (سابقاً)
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const MainLayoutScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: visibleNavItems[_currentIndex]['page'] as Widget,
    );
  }

  void _showSubscriptionLockedDialog(
    BuildContext context,
    String featureName,
    AppLocalizations l10n,
  ) {
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
                Text(l10n.featureLockedTitle), // ✅ مترجم
              ],
            ),
            content: Text(
              "${l10n.featureLockedModelDescPart1}$featureName${l10n.featureLockedModelDescPart2}", // ✅ مترجم مدمج
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancelBtn), // ✅ مترجم
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
                  backgroundColor: _purpleColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.upgradeAccount), // ✅ مترجم
              ),
            ],
          ),
    );
  }
}

// =============================================================================
// ✅ محتوى الصفحة الرئيسية للمودل
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

  Future<void> _checkAgreementAndFetchData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.refreshUser();
    } catch (e) {
      debugPrint("Failed to refresh user data: $e");
    }

    final user = authProvider.user;
    if (user == null) return;

    if (user.hasAcceptedAgreement == false) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder:
            (context) => WillPopScope(
              onWillPop: () async => false,
              child: AgreementModal(
                onAgreed: () async {
                  await _modelService.acceptAgreement();
                  await authProvider.refreshUser();
                  if (mounted) {
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
    // ✅ تعريف الترجمة (بداخل المكون الفرعي)
    final l10n = AppLocalizations.of(context)!;

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
            Text('${l10n.errorPrefix}$_error'), // ✅ مترجم
            ElevatedButton(
              onPressed: _fetchDashboardData,
              child: Text(l10n.retryBtn), // ✅ مترجم
            ),
          ],
        ),
      );
    }

    final user = Provider.of<AuthProvider>(context).user;

    return Stack(
      children: [
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

        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(
                user?.name ?? l10n.defaultModelName,
                l10n,
              ), // ✅ تمرير l10n
              const SizedBox(height: 20),

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
                      l10n.totalEarningsLabel, // ✅ مترجم (سابقاً)
                      "${_stats!.totalEarnings} ${l10n.currencySAR}", // ✅ عملة
                      Icons.attach_money,
                      Colors.green,
                    ),
                    _buildStatCard(
                      l10n.monthlyEarnings, // ✅ مترجم (سابقاً)
                      "${_stats!.monthlyEarnings} ${l10n.currencySAR}", // ✅ عملة
                      Icons.trending_up,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      l10n.agreementsLabel, // ✅ مترجم
                      "${_stats!.completedAgreements}",
                      Icons.check_circle_outline,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      l10n.statusPending, // ✅ مترجم (سابقاً)
                      "${_stats!.pendingRequests}",
                      Icons.access_time,
                      Colors.orange,
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              _buildSectionCard(
                l10n.recentActivity, // ✅ مترجم (سابقاً)
                Icons.history,
                _purpleColor,
                Column(
                  children:
                      _activities.isEmpty
                          ? [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                l10n.noActivities,
                              ), // ✅ مترجم (سابقاً)
                            ),
                          ]
                          : _activities
                              .take(5)
                              .map((act) => _buildActivityItem(act))
                              .toList(),
                ),
              ),

              const SizedBox(height: 24),

              _buildSectionCard(
                l10n.performanceLabel, // ✅ مترجم
                Icons.trending_up,
                _roseColor,
                Column(
                  children: [
                    _buildPerformanceMetric(
                      l10n.responseRate,
                      (_stats?.responseRate ?? 0) / 100,
                    ), // ✅ مترجم (سابقاً)
                    const SizedBox(height: 12),
                    _buildPerformanceMetric(
                      l10n.orderCompletionRate,
                      0.95,
                    ), // ✅ مترجم
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

  Widget _buildWelcomeCard(String name, AppLocalizations l10n) {
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
            "${l10n.welcomeHello}$name 👋", // ✅ مترجم ومدمج
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.performanceSummaryMsg, // ✅ مترجم
            style: const TextStyle(color: Colors.white70, fontSize: 14),
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
