import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // يفضل إضافتها لأيقونات أجمل
import 'package:linyora_project/features/orders/screens/my_orders_screen.dart';

// استيراد الخدمات والموديلات الخاصة بك
// تأكد من تعديل المسارات حسب مشروعك
import '../../auth/services/auth_service.dart';
import '../../../core/utils/color_helper.dart'; // نفترض وجود ملف للألوان

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // محاكاة لجلب البيانات من الـ Auth Service
    // في تطبيقك الحقيقي استخدم: AuthService.instance.currentUser
    final user = AuthService.instance.currentUser;
    final bool isLoggedIn = user != null;

    void _navigateTo(BuildContext context, Widget screen) {
      // 1. التقاط النافجيتور قبل إغلاق القائمة
      final navigator = Navigator.of(context);

      // 2. إغلاق القائمة (هذا يدمر الـ context الحالي للـ Drawer)
      navigator.pop();

      // 3. الانتقال للصفحة الجديدة باستخدام النافجيتور المحفوظ
      navigator.push(MaterialPageRoute(builder: (context) => screen));
    }

    final primaryColor = const Color(0xFFF105C6); // لون Linyora الوردي

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      // SafeArea تجعلها تفتح في الـ Body فقط ولا تغطي شريط الحالة العلوي
      child: SafeArea(
        bottom: true, // نترك الأسفل يمتد
        child: Column(
          children: [
            // 1. الجزء العلوي (معلومات المستخدم أو تسجيل الدخول)
            _buildDrawerHeader(context, isLoggedIn, user, primaryColor),

            // 2. القائمة المنسدلة
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildMenuSection(
                    title: 'تصفح Linyora',
                    items: [
                      _DrawerItem(
                        icon: Icons.local_offer_rounded,
                        title: 'العروض و التخفيضات',
                        onTap: () {},
                      ),
                    ],
                  ),

                  if (isLoggedIn)
                    _buildMenuSection(
                      title: 'حسابي',
                      items: [
                        _DrawerItem(
                          icon: Icons.shopping_bag_outlined,
                          title: 'طلباتي',
                          onTap:
                              () =>
                                  _navigateTo(context, const MyOrdersScreen()),
                        ),
                        _DrawerItem(
                          icon: Icons.favorite_border_rounded,
                          title: 'المفضلة',
                          onTap: () {},
                        ),
                        _DrawerItem(
                          icon: Icons.location_on_outlined,
                          title: 'عناويني',
                          onTap: () {},
                        ),
                        _DrawerItem(
                          icon: Icons.wallet_outlined,
                          title: 'المحفظة',
                          onTap: () {},
                        ),
                      ],
                    ),

                  _buildMenuSection(
                    title: 'الدعم والمعلومات',
                    items: [
                      _DrawerItem(
                        icon: Icons.info_outline_rounded,
                        title: 'من نحن',
                        onTap: () {},
                      ),
                      _DrawerItem(
                        icon: Icons.policy_outlined,
                        title: 'سياسة الخصوصية',
                        onTap: () {},
                      ),
                      _DrawerItem(
                        icon: Icons.support_agent_rounded,
                        title: 'تواصل معنا',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. الفوتر (اللغة وتسجيل الخروج)
            _buildDrawerFooter(context, isLoggedIn),
          ],
        ),
      ),
    );
  }

  // --- Header Section ---
  Widget _buildDrawerHeader(
    BuildContext context,
    bool isLoggedIn,
    dynamic user,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child:
          isLoggedIn
              ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          (user?.avatar != null && user.avatar.isNotEmpty)
                              ? CachedNetworkImageProvider(user.avatar)
                              : null,
                      child:
                          (user?.avatar == null)
                              ? Icon(
                                Icons.person,
                                color: Colors.grey[400],
                                size: 30,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? "مستخدم Linyora",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? "",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // الانتقال لصفحة البروفايل
                    },
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "مرحباً بك في Linyora",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "سجل الدخول لتستمتع بأفضل تجربة تسوق",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to Login
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "تسجيل الدخول / إنشاء حساب",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  // --- Menu Section Builder ---
  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
        Divider(color: Colors.grey.shade100, height: 20),
      ],
    );
  }

  // --- Footer Section ---
  Widget _buildDrawerFooter(BuildContext context, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // أزرار التواصل الاجتماعي (اختياري)
          /* Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialIcon(icon: FontAwesomeIcons.instagram),
              const SizedBox(width: 15),
              _SocialIcon(icon: FontAwesomeIcons.tiktok),
              const SizedBox(width: 15),
              _SocialIcon(icon: FontAwesomeIcons.twitter),
            ],
          ),
          const SizedBox(height: 20), */
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  // تغيير اللغة
                },
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.language,
                        size: 20,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "English",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              if (isLoggedIn)
                InkWell(
                  onTap: () async {
                    // منطق تسجيل الخروج
                    await AuthService.instance.logout();
                    // تحديث الواجهة أو الانتقال للرئيسية
                  },
                  borderRadius: BorderRadius.circular(5),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: const [
                        Icon(Icons.logout, size: 20, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text(
                          "خروج",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            " الإصدار 1.0.0",
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// --- عنصر القائمة (Reusable Widget) ---
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isHighlight;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isHighlight ? const Color(0xFFF105C6) : Colors.black87,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          color: isHighlight ? const Color(0xFFF105C6) : Colors.black87,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      horizontalTitleGap: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      trailing:
          isHighlight
              ? const Icon(Icons.circle, size: 8, color: Color(0xFFF105C6))
              : const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey,
              ),
      onTap: onTap,
    );
  }
}
