import 'package:flutter/material.dart';
import 'package:linyora_project/features/supplier/Verification/screens/verification_screen.dart';
import 'package:linyora_project/features/supplier/bank/screens/supplier_bank_screen.dart';
import 'package:linyora_project/features/supplier/orders/screens/supplier_orders_screen.dart';
import 'package:linyora_project/features/supplier/products/screens/supplier_product_form.dart';
import 'package:linyora_project/features/supplier/products/screens/supplier_products_screen.dart';
import 'package:linyora_project/features/supplier/settings/screens/supplier_settings_screen.dart';
import 'package:linyora_project/features/supplier/shipping/screens/supplier_shipping_screen.dart';
import 'package:linyora_project/features/supplier/stories/screens/stories_screen.dart';
import 'package:linyora_project/features/supplier/wallet/screens/supplier_wallet_screen.dart';
import 'package:provider/provider.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart';

// Services & Models
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    // حماية: إذا لم يكن هناك مستخدم، نعرض تحميل
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ============================================================
    // 1️⃣ منطق الأقفال (Lock Logic) للمورد
    // ============================================================

    // المورد يحتاج فقط للتوثيق للوصول للمميزات (غالباً لا يحتاج اشتراك مثل التاجر)
    final bool isVerified = user.verificationStatus == 'approved';

    // قائمة الصفحات
    final List<Map<String, dynamic>> allNavLinks = [
      {
        'title': 'لوحة التحكم',
        'icon': Icons.dashboard_outlined,
        'page': const _SupplierHomeView(), // ✅ الشاشة الرئيسية الملونة
        'show': true,
        'isLocked': false,
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
        'page': const SupplierProductsScreen(),
        'show': true,
        'isLocked': !isVerified, // 🔒 مقفل حتى يتم التوثيق
      },
      {
        'title': 'القصص',
        'icon': Icons.image_outlined,
        'page': const StoriesScreen(),
        'show': true,
        'isLocked': !isVerified, // 🔒 مقفل حتى يتم التوثيق
      },
      {
        'title': 'الطلبات الواردة',
        'icon': Icons.shopping_bag_outlined,
        'page': const SupplierOrdersScreen(),
        'show': true,
        'isLocked': !isVerified, // 🔒 مقفل
      },
      {
        'title': 'المحفظة والأرباح',
        'icon': Icons.account_balance_wallet_outlined,
        'page': const SupplierWalletScreen(),
        'show': true,
        'isLocked': !isVerified, // 🔒 مقفل
      },
      {
        'title': 'شركات الشحن',
        'icon': Icons.local_shipping_outlined,
        'page': const SupplierShippingScreen(),
        'show': true,
        'isLocked': !isVerified, // 🔒 مقفل
      },
      {
        'title': 'التفاصيل البنكيه',
        'icon': Icons.account_balance_wallet_outlined,
        'page': const SupplierBankScreen(),
        'show': true,
        'isLocked': !isVerified, // 🔒 مقفل
      },
      {
        'title': 'الإعدادات',
        'icon': Icons.settings_outlined,
        'page': const SupplierSettingsScreen(),
        'show': true,
        'isLocked': false,
      },
    ];

    // تصفية العناصر الظاهرة
    final visibleNavItems =
        allNavLinks.where((item) => item['show'] == true).toList();

    // تصحيح المؤشر إذا كان خارج النطاق
    if (_currentIndex >= visibleNavItems.length) _currentIndex = 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8), // لون خلفية هادئ
      // ============================================================
      // 2️⃣ الشريط العلوي (App Bar)
      // ============================================================
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
          onPressed:
              () =>
                  _scaffoldKey.currentState
                      ?.openDrawer(), // فتح القائمة الجانبية
        ),
      ),

      // ============================================================
      // 3️⃣ القائمة الجانبية (Drawer) - نفس ستايل التاجر
      // ============================================================
      drawer: Drawer(
        child: Column(
          children: [
            // رأس القائمة (Header)
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.indigo], // ألوان خاصة بالمورد
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
                  // شارة المورد
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "مورد",
                      style: TextStyle(fontSize: 10, color: Colors.white),
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

            // قائمة العناصر
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
                      Navigator.pop(context); // إغلاق القائمة

                      if (isLocked) {
                        // ⛔️ إذا كان مقفلاً
                        _showLockedDialog(context);
                      } else {
                        // ✅ الانتقال للصفحة
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

      // المحتوى الرئيسي
      body: visibleNavItems[_currentIndex]['page'] as Widget,
    );
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("الميزة مقفلة 🔒"),
            content: const Text(
              "يجب توثيق حساب المورد الخاص بك أولاً للوصول إلى هذه الميزة.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // الانتقال لصفحة التوثيق (يمكنك تحديد الـ index الخاص بها يدوياً)
                  setState(
                    () => _currentIndex = 1,
                  ); // افتراض أن التوثيق هو العنصر الثاني
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("توثيق الحساب"),
              ),
            ],
          ),
    );
  }
}

// -----------------------------------------------------------------------------
// ✅ الشاشة الرئيسية للمورد (نفس تصميم الجراديانت المفضل لديك)
// -----------------------------------------------------------------------------

class _SupplierHomeView extends StatefulWidget {
  const _SupplierHomeView({Key? key}) : super(key: key);

  @override
  State<_SupplierHomeView> createState() => _SupplierHomeViewState();
}

class _SupplierHomeViewState extends State<_SupplierHomeView> {
  final SupplierService _service = SupplierService();
  SupplierStatsModel? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final data = await _service.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        // الخلفية الجمالية
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
              // الترحيب
              const Text(
                "نظرة عامة",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 1. شبكة البطاقات (Stats Grid)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildGradientCard(
                    "الرصيد المتاح",
                    "${_stats!.availableBalance} ر.س",
                    Icons.account_balance_wallet,
                    [Colors.blue.shade400, Colors.indigo.shade500],
                  ),
                  _buildGradientCard(
                    "إجمالي المنتجات",
                    "${_stats!.totalProducts}",
                    Icons.inventory_2,
                    [Colors.green.shade400, Colors.teal.shade500],
                  ),
                  _buildGradientCard(
                    "الطلبات",
                    "${_stats!.totalOrders}",
                    Icons.shopping_cart,
                    [Colors.amber.shade400, Colors.orange.shade600],
                  ),
                  _buildGradientCard("تقييم المورد", "4.9", Icons.star, [
                    Colors.purple.shade400,
                    Colors.deepPurple.shade500,
                  ]),
                ],
              ),

              const SizedBox(height: 24),

              // 2. الإجراءات السريعة (Quick Actions)
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
                      child: const Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            "إجراءات سريعة",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 1️⃣ زر إضافة منتج جديد
                    _buildActionTile(
                      "إضافة منتج جديد",
                      Icons.add_circle_outline,
                      Colors.blue,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    const SupplierProductFormScreen(), // صفحة إضافة المنتج
                          ),
                        );
                      },
                    ),

                    // 2️⃣ زر عرض الطلبات
                    _buildActionTile(
                      "عرض الطلبات الجديدة",
                      Icons.list_alt,
                      Colors.indigo,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    const SupplierOrdersScreen(), // صفحة الطلبات
                          ),
                        );
                      },
                    ),

                    // 3️⃣ زر سحب الرصيد (المحفظة)
                    _buildActionTile(
                      "سحب الرصيد",
                      Icons.account_balance,
                      Colors.green,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    const SupplierWalletScreen(), // صفحة المحفظة
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

  // --- Widgets مساعدة ---

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
      onTap: onTap, // ✅ هنا يتم تفعيل الضغط
    );
  }
}
