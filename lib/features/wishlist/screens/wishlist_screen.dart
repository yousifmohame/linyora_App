import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../../shared/widgets/product_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- 1. حسابات التجاوب (Responsive Calculations) ---
    final double screenWidth = MediaQuery.of(context).size.width;

    // عدد الأعمدة: 2 للموبايل، 3 للتابلت، 4 للشاشات العريضة
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 4 : 2);

    // نسبة الأبعاد: في التابلت نزيد العرض قليلاً لأن البطاقة تكون أعرض
    // 0.48 للموبايل (كما اخترت أنت)، و 0.58 للتابلت لتكون متناسقة
    double childAspectRatio = screenWidth > 600 ? 0.55 : 0.48;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "المفضلة",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, child) {
          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "قائمة المفضلة فارغة",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              // ✅ استخدام القيم الديناميكية هنا
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return ProductCard(
                    product: provider.items[index],
                    // تمرير العرض الفعلي بناءً على حجم العمود
                    width: constraints.maxWidth,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
