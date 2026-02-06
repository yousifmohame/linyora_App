import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:linyora_project/features/products/screens/main_prodects.dart';
import '../providers/cart_provider.dart';
import '../../../models/cart_item_model.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              "سلة التسوق",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const BackButton(color: Colors.black),
            actions: [
              if (cart.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    // إظهار حوار تأكيد قبل الحذف
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text("تفريغ السلة"),
                            content: const Text(
                              "هل أنت متأكد من حذف جميع المنتجات؟",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("إلغاء"),
                              ),
                              TextButton(
                                onPressed: () {
                                  cart.clearCart();
                                  Navigator.pop(ctx);
                                },
                                child: const Text(
                                  "حذف",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                ),
            ],
          ),
          body:
              cart.items.isEmpty
                  ? _buildEmptyCart(context)
                  : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cart.items.length,
                          separatorBuilder:
                              (c, i) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _buildCartItem(
                              context,
                              cart.items[index],
                              cart,
                            );
                          },
                        ),
                      ),
                      _buildCheckoutSection(context, cart),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "سلتك فارغة حالياً",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed:
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductsScreen(),
                  ),
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF105C6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("ابدأ التسوق"),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItemModel item,
    CartProvider cart,
  ) {
    final product = item.product;
    final variant = item.selectedVariant; // قد يكون null

    // ✅ 1. تحديد الصورة: إذا وجد فارينت وله صور نستخدمها، وإلا صورة المنتج
    final String image =
        (variant != null && variant.images.isNotEmpty)
            ? variant.images[0]
            : product.imageUrl;

    // ✅ 2. تحديد السعر: سعر الفارينت أو سعر المنتج
    final double price = variant?.price ?? product.price;

    // ✅ 3. تحديد أقصى كمية مخزون
    final int maxStock = variant?.stockQuantity ?? product.stock;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        cart.removeFromCart(item.id);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم حذف المنتج من السلة")));
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // صورة المنتج
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
              ),
            ),
            const SizedBox(width: 12),

            // التفاصيل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ✅ عرض المواصفات فقط إذا كانت موجودة
                  if (variant != null)
                    Text(
                      "المواصفات: ${variant.name}", // استخدام getter name من المودل
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // السعر
                      Text(
                        "${price.toStringAsFixed(0)} ر.س",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF105C6),
                        ),
                      ),

                      // أزرار الكمية
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _QtyBtn(
                              icon: Icons.remove,
                              onTap: () {
                                if (item.quantity > 1) {
                                  cart.updateQuantity(
                                    item.id,
                                    item.quantity - 1,
                                  );
                                } else {
                                  // يمكن إضافة تأكيد هنا أيضاً
                                  cart.removeFromCart(item.id);
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                "${item.quantity}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _QtyBtn(
                              icon: Icons.add,
                              onTap: () {
                                // ✅ التحقق من المخزون الآمن
                                if (item.quantity < maxStock) {
                                  cart.updateQuantity(
                                    item.id,
                                    item.quantity + 1,
                                  );
                                } else {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "عذراً، هذه أقصى كمية متوفرة",
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    double subtotal = cart.totalAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow(
              "المجموع",
              "${subtotal.toStringAsFixed(2)} ر.س",
              isBold: true,
              color: const Color(0xFFF105C6),
            ),
            const SizedBox(height: 20),

            // زر إتمام الشراء
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckoutScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "إتمام الشراء",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }
}
