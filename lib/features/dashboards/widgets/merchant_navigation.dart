import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class MerchantNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MerchantNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isVerified = user?.verificationStatus == 'approved';
    
    // قائمة الروابط (نفس منطق الويب)
    final List<Map<String, dynamic>> allNavLinks = [
      {'label': 'الرئيسية', 'icon': Icons.home, 'index': 0, 'show': true},
      {'label': 'التوثيق', 'icon': Icons.verified_user, 'index': 1, 'show': !isVerified},
      {'label': 'المنتجات', 'icon': Icons.inventory_2, 'index': 2, 'show': isVerified},
      {'label': 'الطلبات', 'icon': Icons.shopping_cart, 'index': 3, 'show': isVerified},
      {'label': 'القصص', 'icon': Icons.history_edu, 'index': 4, 'show': isVerified}, // Stories
      {'label': 'الشحن', 'icon': Icons.local_shipping, 'index': 5, 'show': isVerified},
      {'label': 'المحفظة', 'icon': Icons.account_balance_wallet, 'index': 6, 'show': isVerified},
      {'label': 'الإعدادات', 'icon': Icons.settings, 'index': 7, 'show': true},
    ];

    // تصفية الروابط المخفية
    final visibleLinks = allNavLinks.where((link) => link['show'] == true).toList();

    return Container(
      height: 70, // ارتفاع الشريط
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2), // ظل علوي خفيف
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: visibleLinks.length,
        itemBuilder: (context, i) {
          final link = visibleLinks[i];
          final bool isActive = currentIndex == link['index'];

          return GestureDetector(
            onTap: () => onTap(link['index']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                // التدرج اللوني عند التفعيل (مثل الويب)
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFF9333EA)], // Rose to Purple
                      )
                    : null,
                color: isActive ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    link['icon'],
                    size: 20,
                    color: isActive ? Colors.white : Colors.grey[700],
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Text(
                      link['label'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}