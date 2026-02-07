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
  final int initialIndex;
  const MainLayoutScreen({super.key, this.initialIndex = 0});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // 2. تعيين الصفحة الحالية بناءً على ما تم تمريره
    _currentIndex = widget.initialIndex;
  }

  // مراجع للمفاتيح لإجبار إعادة بناء ReelsScreen عند تغيير الحالة
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: Colors.grey[100],
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const ProductsScreen(),
          // ✅ أهم تعديل: استخدام Key ثابت + تحديث isActive من _currentIndex
          ReelsScreen(
            key: const PageStorageKey('reels_screen'),
            isActive: _currentIndex == 2,
          ),
          const TrendsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 75.0,
        color: Colors.white,
        buttonBackgroundColor: const Color.fromARGB(255, 241, 5, 198),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: <Widget>[
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
        Icon(icon, size: 26, color: isSelected ? Colors.white : Colors.black),
        if (!isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }
}
