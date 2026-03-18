import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ✅ 1. استيراد الترجمة ومزود اللغة
import 'package:linyora_project/l10n/app_localizations.dart';
import 'package:linyora_project/features/shared/providers/locale_provider.dart';

import 'package:linyora_project/features/agreements/screens/merchant_agreements_screen.dart';
import 'package:linyora_project/features/bank/screens/bank_settings_screen.dart';
import 'package:linyora_project/features/browse/screens/browse_models_screen.dart';
import 'package:linyora_project/features/chat/screens/chat_screen.dart';
import 'package:linyora_project/features/dashboards/MyStore/my_store_screen.dart';
import 'package:linyora_project/features/dropshipping/screens/merchant_dropshipping_screen.dart';
import 'package:linyora_project/features/layout/main_layout_screen.dart';
import 'package:linyora_project/features/settings/screens/settings_screen.dart';
import 'package:linyora_project/features/shared/wallet/screens/wallet_screen.dart';
import 'package:linyora_project/features/shipping/screens/merchant_shipping_screen.dart';
import 'package:linyora_project/features/subscriptions/screens/my_subscription_screen.dart';
import 'package:linyora_project/features/home/screens/notifications_screen.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart';

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

  int _unreadNotificationsCount = 0;
  final MerchantService _merchantService = MerchantService();

  @override
  void initState() {
    super.initState();
    _fetchUnreadNotifications();
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
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

    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isVerified = user.verificationStatus == 'approved';
    final bool isSubscribed = user.isSubscribed;
    final bool hasDropshippingAccess =
        isSubscribed && (user.subscription?.hasDropshippingAccess ?? false);

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
              'title': l10n.subscribeNow, // ✅ مترجم
              'icon': Icons.star_border,
              'page': const SubscriptionPlansScreen(),
              'show': isVerified,
              'isLocked': false,
            };

    final List<Map<String, dynamic>> allNavLinks = [
      {
        'title': l10n.dashboardTitle, // ✅ مترجم
        'icon': Icons.dashboard_outlined,
        'page': const _MerchantHomeView(),
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
        'title': l10n.productsManagement, // ✅ مترجم
        'icon': Icons.inventory_2_outlined,
        'page': const MerchantProductsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.orders, // ✅ مترجم
        'icon': Icons.shopping_bag_outlined,
        'page': const MerchantOrdersScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.storePreview, // ✅ مترجم
        'icon': Icons.store_outlined,
        'page': const MyStoreScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.storeStories, // ✅ مترجم
        'icon': Icons.history_edu_outlined,
        'page': const MerchantStoriesScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.modelsAndInfluencers, // ✅ مترجم
        'icon': Icons.groups_outlined,
        'page': const BrowseModelsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.conversationsTitle, // ✅ مترجم
        'icon': Icons.message_outlined,
        'page': ChatListScreen(currentUserId: user.id),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.agreementsLabel, // ✅ مترجم
        'icon': Icons.handshake_outlined,
        'page': const MerchantAgreementsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.bankInfo, // ✅ مترجم
        'icon': Icons.account_balance_outlined,
        'page': const BankSettingsScreen(),
        'show': isVerified,
        'isLocked': !isSubscribed,
      },
      {
        'title': l10n.dropshipping, // ✅ مترجم
        'icon': Icons.cloud_download_outlined,
        'page': const MerchantDropshippingScreen(),
        'show': isVerified,
        'isLocked': !hasDropshippingAccess,
      },
      subscriptionNavItem,
      {
        'title': l10n.shipping, // ✅ مترجم
        'icon': Icons.local_shipping_outlined,
        'page': const MerchantShippingScreen(),
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
        'title': l10n.settings, // ✅ مترجم
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
        actions: [
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
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
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

          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                setState(() {});
                _fetchUnreadNotifications();
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
                itemCount:
                    visibleNavItems.length +
                    2, // +1 لزر اللغة +1 لزر تسجيل الخروج
                itemBuilder: (context, index) {
                  // ✅✅✅ زر تغيير اللغة المضاف أعلى القائمة ✅✅✅
                  if (index == 0) {
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.language,
                            color: Colors.orange,
                          ),
                          title: Text(
                            l10n.changeLanguageLabel, // ✅ مترجم (أضفناها في لوحة המودل)
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
                            Navigator.pop(context);
                          },
                        ),
                        const Divider(height: 1, indent: 60),
                      ],
                    );
                  }

                  // زر تسجيل الخروج في النهاية
                  if (index == visibleNavItems.length + 1) {
                    return ListTile(
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
                    );
                  }

                  // ضبط الـ index لتخطي زر اللغة
                  final itemIndex = index - 1;
                  final item = visibleNavItems[itemIndex];
                  final bool isSelected = _currentIndex == itemIndex;
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
                        _showSubscriptionLockedDialog(
                          context,
                          item['title'],
                          l10n,
                        ); // ✅ تمرير l10n
                      } else {
                        if (item['title'] == l10n.subscribeNow ||
                            item['title'] == l10n.mySubscription) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => item['page']),
                          );
                        } else {
                          setState(() => _currentIndex = itemIndex);
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

  void _showSubscriptionLockedDialog(
    BuildContext context,
    String featureName,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.lock, color: Color(0xFF9333EA)),
                const SizedBox(width: 8),
                Text(
                  l10n.featureLockedTitle,
                ), // ✅ مترجم (مستخدم مسبقاً في المودل)
              ],
            ),
            content: Text(l10n.featureRequiresSubscriptionMsg(featureName)),
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
                      builder: (context) => const SubscriptionPlansScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E),
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.subscribeNow), // ✅ مترجم
              ),
            ],
          ),
    );
  }
}

// -----------------------------------------------------------------------------
// ✅ محتوى الصفحة الرئيسية
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

  Future<void> _checkAgreementAndFetchData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.refreshUser();
    } catch (e) {
      debugPrint("Warning: Failed to refresh user data: $e");
    }

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
                if (mounted) {
                  _fetchDashboardData();
                }
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
    // ✅ 3. تعريف الترجمة للوحة الداخلية
    final l10n = AppLocalizations.of(context)!;
    final user = Provider.of<AuthProvider>(context).user;
    final isVerified = user?.verificationStatus == 'approved';

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${l10n.errorOccurredMsg} $_error',
              textAlign: TextAlign.center,
            ), // ✅ مترجم
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchDashboardData,
              child: Text(l10n.retryBtn), // ✅ مترجم
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
            _buildVerificationAlert(
              user?.verificationStatus ?? 'pending',
              l10n,
            ), // ✅ تمرير l10n

          const SizedBox(height: 16),
          _buildWelcomeCard(
            user?.name ?? l10n.defaultMerchantName,
            l10n,
          ), // ✅ تمرير l10n

          const SizedBox(height: 16),
          if (_data != null) ...[
            _buildStatsGrid(_data!, l10n), // ✅ تمرير l10n

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.salesAnalysis, // ✅ مترجم
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodButton(l10n.weekly, 'week'), // ✅ مترجم
                      _buildPeriodButton(l10n.monthly, 'month'), // ✅ مترجم
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
            RecentOrdersList(orders: _data!.recentOrders, onViewAll: () {}),
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

  Widget _buildVerificationAlert(String status, AppLocalizations l10n) {
    Color bgColor;
    Color textColor;
    String title;
    String message;

    switch (status) {
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        title = l10n.verificationRejected; // ✅ مترجم
        message = l10n.pleaseReviewAndRetry; // ✅ مترجم
        break;
      case 'not_submitted':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        title = l10n.verificationRequired; // ✅ مترجم
        message = l10n.pleaseCompleteVerification; // ✅ مترجم
        break;
      default:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        title = l10n.underReview; // ✅ مترجم
        message = l10n.dataUnderReviewMsg; // ✅ مترجم
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
              child: Text(
                l10n.startVerification,
                style: TextStyle(color: textColor),
              ), // ✅ مترجم
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(String userName, AppLocalizations l10n) {
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
            '${l10n.welcomeHello}$userName 👋', // ✅ مترجم مدمج
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.storePerformanceToday, // ✅ مترجم
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(MerchantDashboardData data, AppLocalizations l10n) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          title: l10n.totalSales, // ✅ مترجم
          value:
              '${data.totalSales.toStringAsFixed(2)} ${l10n.currencySAR}', // ✅ عملة مترجمة
          icon: Icons.attach_money,
        ),
        StatCard(
          title: l10n.newOrders, // ✅ مترجم
          value: '+${data.recentOrders.length}',
          icon: Icons.shopping_cart_outlined,
        ),
        StatCard(
          title: l10n.activeProducts, // ✅ مترجم
          value: '${data.activeProducts} / ${data.totalProducts}',
          icon: Icons.inventory_2_outlined,
        ),
        StatCard(
          title: l10n.overallRating, // ✅ مترجم
          value: data.averageRating.toStringAsFixed(1),
          description: l10n.fromTotalReviews(
            data.totalReviews.toString(),
          ), // ✅ مترجم ذكي
          icon: Icons.star_border,
        ),
        StatCard(
          title: l10n.monthlyViews, // ✅ مترجم
          value: data.monthlyViews.toString(),
          icon: Icons.visibility_outlined,
        ),
      ],
    );
  }
}
