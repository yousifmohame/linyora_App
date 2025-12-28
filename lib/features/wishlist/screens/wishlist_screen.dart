import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../../shared/widgets/product_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              // ✅ الإصلاح 2: تعديل النسبة لتكون البطاقة أطول وتتسع للمحتوى
              // القيمة الأقل تعني ارتفاعاً أكبر (العرض / الارتفاع)
              childAspectRatio: 0.48,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              // ✅ الإصلاح 3: استخدام LayoutBuilder للحصول على العرض الفعلي
              return LayoutBuilder(
                builder: (context, constraints) {
                  return ProductCard(
                    product: provider.items[index],
                    // تمرير العرض الفعلي بدلاً من infinity
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
