// lib/features/layout/main_layout_screen.dart

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:linyora_project/features/products/screens/main_prodects.dart';
import 'package:linyora_project/features/trends/screens/trends_screen.dart';
import 'package:linyora_project/l10n/app_localizations.dart';

import 'package:linyora_project/features/cart/screens/cart_screen.dart';
import 'package:linyora_project/features/categories/screens/categories_screen.dart';
import '../home/screens/home_screen.dart';
import '../reels/screens/reels_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../shared/widgets/app_drawer.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // 2. الوصول لمتغير الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: Colors.grey[100],

      drawer: const AppDrawer(),
      // نستخدم IndexedStack للحفاظ على حالة الصفحات
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const ProductsScreen(),
          // ✅ التعديل هنا: نمرر isActive لمعرفة هل الصفحة معروضة أم لا
          ReelsScreen(isActive: _currentIndex == 2),
          const TrendsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _currentIndex,
        height: 75.0,
        color: Colors.white,
        buttonBackgroundColor: const Color.fromARGB(255, 241, 5, 198),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: <Widget>[
          // 3. استخدام النصوص المترجمة
          _buildNavItem(Icons.home_outlined, l10n.navHome, 0),
          _buildNavItem(Icons.inventory_2_outlined, l10n.navProducts, 1),
          _buildNavItem(Icons.play_circle_outline, l10n.navReels, 2),
          _buildNavItem(Icons.arrow_outward, l10n.navtrends, 3),
          _buildNavItem(Icons.person_outline, l10n.navProfile, 4),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 26,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
        if (!isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
}
