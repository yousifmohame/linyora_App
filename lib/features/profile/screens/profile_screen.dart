import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/orders/screens/my_orders_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // للوصول لخدمة التوثيق (Singleton)
  final AuthService _authService = AuthService.instance;

  @override
  Widget build(BuildContext context) {
    // التحقق من حالة تسجيل الدخول
    final isLoggedIn = _authService.isLoggedIn;
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "حسابي",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black),
              onPressed: () {
                // الانتقال لصفحة الإعدادات
              },
            ),
        ],
      ),
      body:
          !isLoggedIn
              ? _buildGuestView() // 1. عرض الزائر
              : SingleChildScrollView(
                // 2. عرض المستخدم المسجل
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // رأس الصفحة (الصورة والاسم)
                    _buildProfileHeader(user),

                    const SizedBox(height: 20),

                    // إحصائيات سريعة (اختياري - مثل الموقع)
                    _buildStatsRow(),

                    const SizedBox(height: 20),

                    // القوائم
                    _buildMenuSection(
                      title: "الطلبات والمشتريات",
                      children: [
                        _ProfileTile(
                          icon: Icons.shopping_bag_outlined,
                          title: "طلباتي",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyOrdersScreen(),
                              ),
                            );
                          },
                        ),
                        _ProfileTile(
                          icon: Icons.favorite_border,
                          title: "المفضلة",
                          onTap: () {},
                        ),
                        _ProfileTile(
                          icon: Icons.assignment_return_outlined,
                          title: "المرتجعات",
                          onTap: () {},
                        ),
                      ],
                    ),

                    _buildMenuSection(
                      title: "الحساب والمحفظة",
                      children: [
                        _ProfileTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: "المحفظة",
                          subtitle: "0.00 ر.س",
                          onTap: () {},
                        ),
                        _ProfileTile(
                          icon: Icons.location_on_outlined,
                          title: "عناويني",
                          onTap: () {},
                        ),
                        _ProfileTile(
                          icon: Icons.credit_card_outlined,
                          title: "طرق الدفع",
                          onTap: () {},
                        ),
                      ],
                    ),

                    _buildMenuSection(
                      title: "التطبيق",
                      children: [
                        _ProfileTile(
                          icon: Icons.language,
                          title: "اللغة / Language",
                          trailingText: "العربية",
                          onTap: () {},
                        ),
                        _ProfileTile(
                          icon: Icons.help_outline,
                          title: "المساعدة والدعم",
                          onTap: () {},
                        ),
                        _ProfileTile(
                          icon: Icons.info_outline,
                          title: "عن Linyora",
                          onTap: () {},
                        ),
                      ],
                    ),

                    // زر تسجيل الخروج
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _authService.logout();
                            // إعادة بناء الصفحة أو التوجيه
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text("تسجيل الخروج"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      "الإصدار 1.0.0",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 80), // مسافة للفوتر السفلي
                  ],
                ),
              ),
    );
  }

  // --- 1. واجهة الزائر ---
  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF105C6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 60,
                color: Color(0xFFF105C6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "قم بتسجيل الدخول للاستمتاع بتجربة تسوق كاملة",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF105C6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("تسجيل الدخول / إنشاء حساب"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. مكونات البروفايل ---

  Widget _buildProfileHeader(dynamic user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // الصورة
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF105C6), width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  (user?.avatar != null && user.avatar.isNotEmpty)
                      ? CachedNetworkImageProvider(user.avatar)
                      : null,
              child:
                  (user?.avatar == null)
                      ? const Icon(Icons.person, size: 35, color: Colors.grey)
                      : null,
            ),
          ),
          const SizedBox(width: 15),
          // البيانات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? "مستخدم Linyora",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? "",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    // تعديل الملف الشخصي
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "تعديل الملف الشخصي",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("0", "الطلبات"),
          _buildVerticalDivider(),
          _buildStatItem("0", "المتابعين"),
          _buildVerticalDivider(),
          _buildStatItem("0", "قسائم"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFFF105C6),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[200]);
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(color: Colors.white, child: Column(children: children)),
      ],
    );
  }
}

// --- عنصر القائمة (Tile) ---
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFF105C6), size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle:
              subtitle != null
                  ? Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )
                  : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
        Divider(height: 1, indent: 60, color: Colors.grey[100]), // فاصل خفيف
      ],
    );
  }
}
