import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart'; // 📦 تأكد من استيراد المكتبة

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

  // قائمة الصفحات
  final List<Widget> _screens = [
    const HomeScreen(), // 0: الرئيسية
    const Center(
      child: Text("المتجر", style: TextStyle(fontSize: 20)),
    ), // 1: الأقسام
    const ReelsScreen(), // 2: الريلز
    const Center(
      child: Text("السلة", style: TextStyle(fontSize: 20)),
    ), // 3: السلة
    const ProfileScreen(), // 4: الملف الشخصي
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[100],
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _currentIndex,
        height: 75.0, // 👈 زدنا الارتفاع قليلاً ليتسع للنص
        // 🎨 الألوان
        color: Colors.white,
        buttonBackgroundColor: const Color.fromARGB(255, 241, 5, 198),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),

        // 👇 التغيير هنا: دالة لبناء الأيقونة مع النص
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

  // 🛠️ دالة مساعدة لبناء الأيقونة مع النص بشكل مرتب
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 26, // تصغير الأيقونة قليلاً
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
        // عرض النص فقط إذا لم يكن العنصر مختاراً (لأن الدائرة صغيرة)
        // أو يمكنك حذف الشرط لعرض النص دائماً
        if (!isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9, // خط صغير جداً ليناسب المساحة
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
}
