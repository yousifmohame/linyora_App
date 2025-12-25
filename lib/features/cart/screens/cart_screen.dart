import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  List<CartItemModel> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final items = await _cartService.getCartItems();
    if (mounted) {
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    }
  }

  // حساب المجموع
  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get _shipping => 20.0; // قيمة ثابتة للشحن كمثال
  double get _total => _subtotal + _shipping;

  void _updateQuantity(int index, int delta) {
    final item = _cartItems[index];
    final newQty = item.quantity + delta;

    if (newQty > 0) {
      setState(() {
        item.quantity = newQty;
      });
      // إرسال التحديث للسيرفر بصمت
      _cartService.updateQuantity(item.id, newQty);
    }
  }

  void _removeItem(int index) {
    final item = _cartItems[index];
    setState(() {
      _cartItems.removeAt(index);
    });
    _cartService.removeItem(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم حذف المنتج من السلة")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("سلة التسوق", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        // leading: const BackButton(color: Colors.black), // يمكن إخفاؤها إذا كانت في الـ MainLayout
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF105C6)))
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    // قائمة المنتجات
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartItems.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildCartItem(_cartItems[index], index);
                        },
                      ),
                    ),
                    
                    // ملخص الفاتورة وزر الدفع
                    _buildCheckoutSection(),
                  ],
                ),
    );
  }

  Widget _buildEmptyCart() {
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
            child: const Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            "سلتك فارغة حالياً",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // العودة للتسوق (يمكنك تفعيل هذا لاحقاً للذهاب للرئيسية)
              // Navigator.of(context).pushNamed('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF105C6),
              foregroundColor: Colors.white,
            ),
            child: const Text("ابدأ التسوق"),
          )
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item, int index) {
    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(index),
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
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // الصورة
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.image,
                width: 80, height: 80, fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
              ),
            ),
            const SizedBox(width: 12),
            
            // التفاصيل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  // الخيارات (لون/مقاس)
                  if (item.color != null || item.size != null)
                    Text(
                      "${item.color ?? ''} ${item.size != null ? '| ${item.size}' : ''}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  
                  // السعر والكمية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${item.price} ر.س",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF105C6)),
                      ),
                      
                      // أزرار التحكم بالكمية
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _QtyBtn(icon: Icons.remove, onTap: () => _updateQuantity(index, -1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            _QtyBtn(icon: Icons.add, onTap: () => _updateQuantity(index, 1)),
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

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow("المجموع الفرعي", "$_subtotal ر.س"),
            const SizedBox(height: 8),
            _buildSummaryRow("الشحن", "$_shipping ر.س"),
            const Divider(height: 24),
            _buildSummaryRow("الإجمالي", "$_total ر.س", isBold: true, color: const Color(0xFFF105C6)),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // الانتقال لصفحة إتمام الطلب (Checkout)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("إتمام الشراء", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
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