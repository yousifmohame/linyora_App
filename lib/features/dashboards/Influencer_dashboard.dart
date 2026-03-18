import 'dart:async';
import 'package:flutter/material.dart';

// ✅ 1. استيراد ملف الترجمة ومزود اللغة
import 'package:linyora_project/l10n/app_localizations.dart';
import 'package:linyora_project/features/shared/providers/locale_provider.dart';

import 'package:linyora_project/features/influencers/bank/screens/model_bank_settings_screen.dart';
import 'package:linyora_project/features/influencers/notifications/screens/notification_screen.dart';
import 'package:linyora_project/features/influencers/notifications/services/notifications_service.dart';
import 'package:linyora_project/features/influencers/offers/screens/model_offers_screen.dart';
import 'package:linyora_project/features/influencers/profile/screens/model_profile_settings.dart';
import 'package:linyora_project/features/influencers/requests/screens/model_requests_screen.dart';
import 'package:linyora_project/features/influencers/services/model_service.dart';
import 'package:linyora_project/features/influencers/stories/screens/stories_screen.dart';
import 'package:linyora_project/features/influencers/verification/screens/verification_screen.dart';
import 'package:linyora_project/features/layout/main_layout_screen.dart';
import 'package:linyora_project/features/models/analytics/screens/model_analytics_screen.dart';
import 'package:linyora_project/features/models/reels/screens/model_reels_screen.dart';
import 'package:linyora_project/features/public_profiles/screens/model_profile_screen.dart';
import 'package:linyora_project/features/shared/wallet/screens/wallet_screen.dart';
import 'package:provider/provider.dart';

// Providers & Services
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/models/models/model_dashboard_models.dart';

// Screens
import 'package:linyora_project/features/chat/screens/chat_screen.dart';
import 'package:linyora_project/features/subscriptions/screens/subscription_plans_screen.dart';
import 'package:linyora_project/features/subscriptions/screens/my_subscription_screen.dart';
import 'package:linyora_project/features/models/screens/agreement_model.dart';

class InfluencerDashboardScreen extends StatefulWidget {
  const InfluencerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<InfluencerDashboardScreen> createState() =>
      _InfluencerDashboardScreenState();
}

class _InfluencerDashboardScreenState extends State<InfluencerDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Color _primaryColor = const Color(0xFF4F46E5);
  final Color _accentColor = const Color(0xFF06B6D4);
  final Color _backgroundColor = const Color(0xFFF3F4F6);

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
              'title': l10n.currentPackage, // ✅ مترجم
              'icon': Icons.card_membership,
              'page': const MySubscriptionScreen(),
              'show': isVerified,
              'isLocked': false,
            }
            : {
              'title': l10n.upgradeAccount, // ✅ مترجم
              'icon': Icons.rocket_launch,
              'page': const SubscriptionPlansScreen(),
              'show': isVerified,
              'isLocked': false,
            };

    final List<Map<String, dynamic>> allNavLinks = [
      {
        'title': l10n.influencerDashboardTitle, // ✅ مترجم
        'icon': Icons.grid_view_rounded,
        'page': const _InfluencerHomeView(),
        'show': true,
        'isLocked': false,
      },
      {
        'title': l10n.accountVerification, // ✅ مترجم
        'icon': Icons.verified_user_outlined,
        'page': const VerificationScreen(),
        'show': !isVerified,
        'isLocked': false,
      },
      {
        'title': l10n.myOffers, // ✅ مترجم
        'icon': Icons.local_offer_outlined,
        'page': const InfluencerOffersScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.reels, // ✅ مترجم
        'icon': Icons.video_call_outlined,
        'page': const ModelReelsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.collabRequests, // ✅ مترجم
        'icon': Icons.handshake_outlined,
        'page': const InfluencerRequestsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.stories, // ✅ مترجم
        'icon': Icons.amp_stories_outlined,
        'page': const InfluencerStoriesScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.analyticsAndPerformance, // ✅ مترجم
        'icon': Icons.insights_outlined,
        'page': const ModelAnalyticsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.financialWallet, // ✅ مترجم
        'icon': Icons.account_balance_wallet_outlined,
        'page': const WalletScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.messages, // ✅ مترجم
        'icon': Icons.chat_bubble_outline,
        'page': ChatListScreen(currentUserId: user.id),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      subscriptionNavItem,
      {
        'title': l10n.bankAccount, // ✅ مترجم
        'icon': Icons.account_balance_outlined,
        'page': const InfluencerBankSettingsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.profile, // ✅ مترجم
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
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none_outlined,
                      color: _primaryColor,
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
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
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
                            style: const TextStyle(fontSize: 11),
                          ), // ✅ مترجم (أضفناها في الشاشة السابقة)
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
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // ✅✅✅ زر تغيير اللغة المضاف هنا أعلى القائمة ✅✅✅
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.language,
                          color: Colors.orange,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        l10n.changeLanguageLabel, // ✅ مترجم
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
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

                    // عرض باقي أزرار الـ Navigation
                    ...List.generate(visibleNavItems.length, (index) {
                      final item = visibleNavItems[index];
                      final bool isSelected = _currentIndex == index;
                      final bool isLocked = item['isLocked'] == true;

                      return Column(
                        children: [
                          ListTile(
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
                                _showSubscriptionLockedDialog(
                                  context,
                                  item['title'],
                                  l10n,
                                ); // ✅ تمرير الترجمة
                              } else {
                                setState(() => _currentIndex = index);
                              }
                            },
                          ),
                          const Divider(height: 1, indent: 60),
                        ],
                      );
                    }),

                    // زر تسجيل الخروج في النهاية
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        l10n.logout, // ✅ مترجم
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
            ),
          ],
        ),
      ),
      body: visibleNavItems[_currentIndex]['page'] as Widget,
    );
  }

  // ✅ تمرير l10n واستخدام المتغيرات
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
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.workspace_premium, color: _primaryColor),
                const SizedBox(width: 8),
                Text(l10n.exclusiveFeature), // ✅ مترجم
              ],
            ),
            content: Text(
              "${l10n.featureLockedPart1}$featureName${l10n.featureLockedPart2}", // ✅ دمج مترجم
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.notNow, // ✅ مترجم
                  style: const TextStyle(color: Colors.grey),
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
                child: Text(l10n.upgradeNow), // ✅ مترجم
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

    try {
      await authProvider.refreshUser();
    } catch (e) {}

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
                  if (mounted) {
                    Navigator.pop(context);
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
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
    // ✅ 3. تعريف الترجمة للوحة الداخلية
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _indigo));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.errorLoadingData), // ✅ مترجم
            ElevatedButton(
              onPressed: _fetchDashboardData,
              child: Text(l10n.tryAgain), // ✅ مترجم
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
              _buildModernWelcomeCard(
                user?.name ?? l10n.defaultInfluencerName,
                l10n,
              ), // ✅ تمرير l10n
              const SizedBox(height: 24),

              if (_stats != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        l10n.totalBalance, // ✅ مترجم
                        "${_stats!.totalEarnings}",
                        l10n.currencySAR, // ✅ مترجم
                        Icons.wallet,
                        _indigo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        l10n.activeRequests, // ✅ مترجم
                        "${_stats!.pendingRequests}",
                        l10n.requestUnit, // ✅ مترجم
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
                        l10n.monthlyEarnings, // ✅ مترجم
                        "${_stats!.monthlyEarnings}",
                        l10n.currencySAR, // ✅ مترجم
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        l10n.viewsLabel, // ✅ مترجم
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

              Text(
                l10n.recentActivity, // ✅ مترجم
                style: const TextStyle(
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
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                l10n.noActivities, // ✅ مترجم
                                style: const TextStyle(color: Colors.grey),
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
                _buildPerformanceCard(
                  (_stats!.responseRate ?? 0) / 100,
                  l10n,
                ), // ✅ تمرير l10n

              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernWelcomeCard(String name, AppLocalizations l10n) {
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
                l10n.welcomeBack, // ✅ مترجم
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
                  "Level: Pro Influencer", // هذه يمكن تركها إنجليزية لأنها مصطلح تقني خاص بالمنصة، أو ترجمتها
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

  Widget _buildPerformanceCard(double rate, AppLocalizations l10n) {
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
                Text(
                  l10n.responseRate, // ✅ مترجم
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.excellentInteraction, // ✅ مترجم
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
