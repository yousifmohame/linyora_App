import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/address/screens/addresses_screen.dart';
import 'package:linyora_project/features/home/screens/AboutLinyoraScreen.dart';
import 'package:linyora_project/features/home/screens/contact_us_screen.dart';
import 'package:linyora_project/features/payment/screens/payment_methods_screen.dart';
import 'package:linyora_project/features/profile/screens/EditProfileScreen.dart';
import 'package:linyora_project/features/trends/screens/trends_screen.dart';

import 'package:linyora_project/features/wishlist/screens/wishlist_screen.dart';
import 'package:provider/provider.dart';
import 'package:linyora_project/l10n/app_localizations.dart';

// تأكد من المسارات الصحيحة
import '../../orders/screens/my_orders_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../shared/providers/locale_provider.dart'; // استيراد البروفايدر

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService.instance;

  @override
  Widget build(BuildContext context) {
    // 1. الوصول للترجمة
    final l10n = AppLocalizations.of(context)!;

    final isLoggedIn = _authService.isLoggedIn;
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.myProfile, // استخدام الترجمة
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black),
              onPressed: () async {
                // الانتقال لصفحة التعديل
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
                // عند العودة، نقوم بتحديث الصفحة لرؤية البيانات الجديدة
                setState(() {});
              },
            ),
        ],
      ),
      body:
          !isLoggedIn
              ? _buildGuestView(context, l10n)
              : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(user, l10n),
                    const SizedBox(height: 20),
                    _buildStatsRow(l10n),
                    const SizedBox(height: 20),

                    // القوائم
                    _buildMenuSection(
                      title: l10n.ordersAndPurchases,
                      children: [
                        _ProfileTile(
                          icon: Icons.shopping_bag_outlined,
                          title: l10n.myOrders,
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
                          title: l10n.favorites,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WishlistScreen(),
                              ),
                            );
                          },
                        ),
                        _ProfileTile(
                          icon: Icons.assignment_return_outlined,
                          title: l10n.trends,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TrendsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    _buildMenuSection(
                      title: l10n.accountAndWallet,
                      children: [
                        _ProfileTile(
                          icon: Icons.location_on_outlined,
                          title: l10n.myAddresses, // أو l10n.addresses
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddressesScreen(),
                              ),
                            );
                          },
                        ),
                        _ProfileTile(
                          icon: Icons.credit_card_outlined,
                          title: l10n.paymentMethods,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const PaymentMethodsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    _buildMenuSection(
                      title: l10n.appSettings,
                      children: [
                        // زر اللغة
                        _ProfileTile(
                          icon: Icons.language,
                          title: l10n.language,
                          // عرض اللغة الحالية
                          trailingText:
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'العربية'
                                  : 'English',
                          onTap: () => _showLanguageBottomSheet(context),
                        ),
                        _ProfileTile(
                          icon: Icons.help_outline,
                          title: l10n.helpAndSupport,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ContactUsScreen(),
                              ),
                            );
                          },
                        ),
                        _ProfileTile(
                          icon: Icons.info_outline,
                          title: l10n.aboutApp,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AboutLinyoraScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _authService.logout();
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
                          label: Text(l10n.logout),
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
                      "${l10n.version} 1.0.0",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
    );
  }

  // دالة إظهار نافذة اختيار اللغة
  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final provider = Provider.of<LocaleProvider>(context, listen: false);
        final currentLang = provider.locale.languageCode;

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.language,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Text("🇸🇦", style: TextStyle(fontSize: 24)),
                title: const Text("العربية"),
                trailing:
                    currentLang == 'ar'
                        ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFFF105C6),
                        )
                        : null,
                onTap: () {
                  provider.setLocale(const Locale('ar'));
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
                title: const Text("English"),
                trailing:
                    currentLang == 'en'
                        ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFFF105C6),
                        )
                        : null,
                onTap: () {
                  provider.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestView(BuildContext context, AppLocalizations l10n) {
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
            Text(
              l10n.guestTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                child: Text(l10n.loginSignup),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user, AppLocalizations l10n) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? l10n.userGuest,
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
                // داخل _buildProfileHeader
                InkWell(
                  onTap: () async {
                    // الانتقال لصفحة التعديل
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                    // عند العودة، نقوم بتحديث الصفحة لرؤية البيانات الجديدة
                    setState(() {});
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
                    child: Text(
                      l10n.editProfile,
                      style: const TextStyle(
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

  Widget _buildStatsRow(AppLocalizations l10n) {
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
          _buildStatItem("0", l10n.statsOrders),
          _buildVerticalDivider(),
          _buildStatItem("0", l10n.statsFollowers),
          _buildVerticalDivider(),
          _buildStatItem("0", l10n.statsVouchers),
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
        Divider(height: 1, indent: 60, color: Colors.grey[100]),
      ],
    );
  }
}
