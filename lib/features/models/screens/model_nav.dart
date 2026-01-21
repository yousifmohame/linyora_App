import 'package:flutter/material.dart';
import 'package:linyora_project/features/auth/services/auth_service.dart';
import 'package:linyora_project/features/auth/screens/login_screen.dart'; // لتسجيل الخروج

class ModelDrawer extends StatelessWidget {
  const ModelDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    // التحقق من حالة التحقق والاشتراك (افترضنا وجود هذه الحقول في المودل)
    bool isVerified = true; // user?.verificationStatus == 'approved';
    bool isSubscribed = true; // user?.subscriptionStatus == 'active';

    return Drawer(
      child: Column(
        children: [
          // 1. Header with Gradient
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFF9333EA)], // Rose to Purple
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(user?.name ?? "المودل", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(user?.email ?? "model@example.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.name ?? "M")[0].toUpperCase(),
                style: const TextStyle(fontSize: 30, color: Color(0xFF9333EA), fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 2. Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(context, 'الرئيسية', Icons.home, '/model/dashboard'),
                
                if (isVerified) ...[
                  _buildDrawerItem(context, 'العروض', Icons.shopping_bag, '/model/offers'),
                  _buildDrawerItem(context, 'الطلبات', Icons.handshake, '/model/requests'),
                  _buildDrawerItem(context, 'القصص', Icons.history_toggle_off, '/model/stories'),
                  _buildDrawerItem(context, 'المحفظة', Icons.account_balance_wallet, '/model/wallet'),
                  _buildDrawerItem(context, 'Reels', Icons.videocam, '/model/reels'),
                  _buildDrawerItem(context, 'التحليلات', Icons.bar_chart, '/model/analytics'),
                  _buildDrawerItem(context, 'الرسائل', Icons.message, '/model/messages'),
                  _buildDrawerItem(context, 'الحساب البنكي', Icons.account_balance, '/model/bank'),
                  _buildDrawerItem(context, 'الملف الشخصي', Icons.person, '/model/profile'),
                ] else ...[
                  _buildDrawerItem(context, 'توثيق الحساب', Icons.verified_user, '/model/verification', iconColor: Colors.amber),
                ],

                if (isSubscribed)
                  _buildDrawerItem(context, 'اشتراكي', Icons.credit_card, '/model/subscription')
                else
                  _buildDrawerItem(context, 'الاشتراك', Icons.shopping_cart, '/model/subscribe', iconColor: Colors.green),
              ],
            ),
          ),

          // 3. Logout
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await AuthService.instance.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, String route, {Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context); // إغلاق الـ Drawer
        // Navigator.pushNamed(context, route); // تفعيل التنقل لاحقاً
      },
    );
  }
}