import 'package:flutter/material.dart';
import 'package:linyora_project/features/layout/main_layout_screen.dart';
import 'package:linyora_project/features/shared/wallet/screens/wallet_screen.dart';
import 'package:linyora_project/features/supplier/Verification/screens/verification_screen.dart';
import 'package:linyora_project/features/supplier/bank/screens/supplier_bank_screen.dart';
import 'package:linyora_project/features/supplier/orders/screens/supplier_orders_screen.dart';
import 'package:linyora_project/features/supplier/products/screens/supplier_product_form.dart';
import 'package:linyora_project/features/supplier/products/screens/supplier_products_screen.dart';
import 'package:linyora_project/features/supplier/settings/screens/supplier_settings_screen.dart';
import 'package:linyora_project/features/supplier/shipping/screens/supplier_shipping_screen.dart';
import 'package:linyora_project/features/supplier/stories/screens/stories_screen.dart';
import 'package:linyora_project/features/supplier/wallet/screens/supplier_wallet_screen.dart';
import 'package:linyora_project/features/home/screens/notifications_screen.dart';
import 'package:provider/provider.dart';

// ✅ 1. استيراد الترجمة ומزود اللغة
import 'package:linyora_project/l10n/app_localizations.dart';
import 'package:linyora_project/features/shared/providers/locale_provider.dart';

import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/features/supplier/services/supplier_service.dart';

class SupplierDashboardScreen extends StatefulWidget {
  const SupplierDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SupplierDashboardScreen> createState() =>
      _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends State<SupplierDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _unreadNotificationsCount = 0;
  final SupplierService _supplierService = SupplierService();

  @override
  void initState() {
    super.initState();
    _fetchUnreadNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserProfile();
    });
  }

  Future<void> _refreshUserProfile() async {
    try {
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
    } catch (e) {
      debugPrint("Error refreshing user profile: $e");
    }
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final notifications = await _supplierService.getNotifications();
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

    final List<Map<String, dynamic>> allNavLinks = [
      {
        'title': l10n.dashboardTitle, // ✅ مترجم (استخدمناه مسبقاً)
        'icon': Icons.dashboard_outlined,
        'page': const _SupplierHomeView(),
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
        'page': const SupplierProductsScreen(),
        'show': true,
        'isLocked': !isVerified,
      },
      {
        'title': l10n.stories, // ✅ مترجم
        'icon': Icons.image_outlined,
        'page': const StoriesScreen(),
        'show': true,
        'isLocked': !isVerified,
      },
      {
        'title': l10n.incomingOrders, // ✅ مترجم
        'icon': Icons.shopping_bag_outlined,
        'page': const SupplierOrdersScreen(),
        'show': true,
        'isLocked': !isVerified,
      },
      {
        'title': l10n.walletAndEarnings, // ✅ مترجم
        'icon': Icons.account_balance_wallet_outlined,
        'page': const WalletScreen(),
        'show': true,
        'isLocked': !isVerified,
      },
      {
        'title': l10n.shippingCompanies, // ✅ مترجم
        'icon': Icons.local_shipping_outlined,
        'page': const SupplierShippingScreen(),
        'show': true,
        'isLocked': !isVerified,
      },
      {
        'title': l10n.bankDetailsTitle, // ✅ مترجم
        'icon': Icons.account_balance_wallet_outlined,
        'page': const SupplierBankScreen(),
        'show': true,
        'isLocked': !isVerified,
      },
      {
        'title': l10n.settings, // ✅ مترجم
        'icon': Icons.settings_outlined,
        'page': const SupplierSettingsScreen(),
        'show': true,
        'isLocked': false,
      },
    ];

    final visibleNavItems =
        allNavLinks.where((item) => item['show'] == true).toList();

    if (_currentIndex >= visibleNavItems.length) _currentIndex = 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
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
          const SizedBox(width: 8),
        ],
      ),

      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.indigo],
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
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.blue,
                          ),
                        )
                        : null,
              ),
              accountName: Row(
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.supplierRoleLabel, // ✅ مترجم
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
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
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount:
                    visibleNavItems.length + 2, // +1 زر اللغة, +1 لتسجيل الخروج
                itemBuilder: (context, index) {
                  // ✅✅✅ إضافة زر تغيير اللغة ✅✅✅
                  if (index == 0) {
                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.language,
                            color: Colors.orange,
                          ),
                          title: Text(
                            l10n.changeLanguageLabel, // ✅ مترجم (مستخدم سابقاً)
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

                  if (index == visibleNavItems.length + 1) {
                    return ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        l10n.logout, // ✅ مترجم (مستخدم سابقاً)
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

                  final itemIndex = index - 1; // تعويض مكان زر اللغة
                  final item = visibleNavItems[itemIndex];
                  final bool isSelected = _currentIndex == itemIndex;
                  final bool isLocked = item['isLocked'] == true;

                  return ListTile(
                    leading: Icon(
                      item['icon'],
                      color:
                          isLocked
                              ? Colors.grey
                              : (isSelected ? Colors.blue : Colors.grey[600]),
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
                                        ? Colors.blue
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
                    selectedTileColor: Colors.blue.withOpacity(0.05),
                    onTap: () {
                      Navigator.pop(context);
                      if (isLocked) {
                        _showLockedDialog(context, l10n); // ✅ تمرير l10n
                      } else {
                        setState(() => _currentIndex = itemIndex);
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

  void _showLockedDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.featureLockedTitle), // ✅ مترجم (استخدمناه مسبقاً)
            content: Text(l10n.featureLockedDesc), // ✅ مترجم
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancelBtn), // ✅ مترجم
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1); // التوجيه لصفحة التوثيق
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text(l10n.verifyAccountBtn), // ✅ مترجم
              ),
            ],
          ),
    );
  }
}

// -----------------------------------------------------------------------------
// محتوى الصفحة الرئيسية
// -----------------------------------------------------------------------------
class _SupplierHomeView extends StatefulWidget {
  const _SupplierHomeView({Key? key}) : super(key: key);

  @override
  State<_SupplierHomeView> createState() => _SupplierHomeViewState();
}

class _SupplierHomeViewState extends State<_SupplierHomeView> {
  // لا نحتاج للبيانات الحقيقية في هذا الملف لأن الـ SupplierHomeView المحدثة
  // تم تعريفها في ملف منفصل (supplier_home_view.dart أو مشابه) حسب مشروعك
  // لكن قمت بترجمة هذا الجزء الموجود في هذا الملف للاحتياط.

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: _blurCircle(Colors.blue.withOpacity(0.15)),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: _blurCircle(Colors.indigo.withOpacity(0.15)),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.overviewTitle, // ✅ مترجم
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildGradientCard(
                    l10n.availableBalanceLabel, // ✅ مترجم
                    "1500 ${l10n.currencySAR}",
                    Icons.account_balance_wallet,
                    [Colors.blue.shade400, Colors.indigo.shade500],
                  ),
                  _buildGradientCard(
                    l10n.totalProductsLabel, // ✅ مترجم
                    "42",
                    Icons.inventory_2,
                    [Colors.green.shade400, Colors.teal.shade500],
                  ),
                  _buildGradientCard(
                    l10n.orders, // ✅ مترجم
                    "128",
                    Icons.shopping_cart,
                    [Colors.amber.shade400, Colors.orange.shade600],
                  ),
                  _buildGradientCard(
                    l10n.supplierRatingLabel, // ✅ مترجم
                    "4.9",
                    Icons.star,
                    [Colors.purple.shade400, Colors.deepPurple.shade500],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF0F0F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            l10n.quickActionsTitle, // ✅ مترجم
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildActionTile(
                      l10n.addNewProductAction, // ✅ مترجم
                      Icons.add_circle_outline,
                      Colors.blue,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupplierProductFormScreen(),
                          ),
                        );
                      },
                    ),

                    _buildActionTile(
                      l10n.viewNewOrdersAction, // ✅ مترجم
                      Icons.list_alt,
                      Colors.indigo,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupplierOrdersScreen(),
                          ),
                        );
                      },
                    ),

                    _buildActionTile(
                      l10n.withdrawBalanceAction, // ✅ مترجم
                      Icons.account_balance,
                      Colors.green,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupplierWalletScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  Widget _blurCircle(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildGradientCard(
    String title,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: Colors.white70, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
