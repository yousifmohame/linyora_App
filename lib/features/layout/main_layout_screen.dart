// lib/features/layout/main_layout_screen.dart

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../home/screens/home_screen.dart';
import '../reels/screens/reels_screen.dart';
import '../profile/screens/profile_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[100],
      // نستخدم IndexedStack للحفاظ على حالة الصفحات
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const Center(child: Text("المتجر")),
          // ✅ التعديل هنا: نمرر isActive لمعرفة هل الصفحة معروضة أم لا
          ReelsScreen(isActive: _currentIndex == 2), 
          const Center(child: Text("السلة")),
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
          _buildNavItem(Icons.home_outlined, 'الرئيسية', 0),
          _buildNavItem(Icons.grid_view_outlined, 'الأقسام', 1),
          _buildNavItem(Icons.play_circle_outline, 'ريلز', 2),
          _buildNavItem(Icons.shopping_cart_outlined, 'السلة', 3),
          _buildNavItem(Icons.person_outline, 'حسابي', 4),
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
                  color: Colors.grey),
            ),
          ),
      ],
    );
  }
}