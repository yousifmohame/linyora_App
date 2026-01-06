import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/order_model.dart';
import '../services/order_service.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  List<OrderModel> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    // محاكاة تأخير بسيط لإظهار جمالية التحميل (اختياري)
    // await Future.delayed(const Duration(seconds: 1));
    final orders = await _orderService.getMyOrders();
    if (mounted) {
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    }
  }

  List<OrderModel> _getOrdersByStatus(String statusFilter) {
    if (statusFilter == 'all') return _allOrders;
    return _allOrders
        .where((o) => o.status.toLowerCase() == statusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // خلفية رمادية فاتحة جداً عصرية
      appBar: AppBar(
        title: const Text(
          "طلباتي",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800, // خط سميك وعصري
            fontSize: 22,
          ),
        ),
        centerTitle: false, // العنوان لليمين (أو اليسار حسب اللغة) أكثر حداثة
        backgroundColor: Colors.white,
        elevation: 0.5, // ظل خفيف جداً
        leading: const BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFF105C6),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFFF105C6),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label, // المؤشر بحجم النص فقط
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: "الكل"),
            Tab(text: "قيد التجهيز"),
            Tab(text: "تم الشحن"),
            Tab(text: "تم التوصيل"),
            Tab(text: "ملغي"),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF105C6)),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _OrdersListView(orders: _getOrdersByStatus('all')),
                  _OrdersListView(orders: _getOrdersByStatus('processing')),
                  _OrdersListView(orders: _getOrdersByStatus('shipped')),
                  _OrdersListView(orders: _getOrdersByStatus('delivered')),
                  _OrdersListView(orders: _getOrdersByStatus('cancelled')),
                ],
              ),
    );
  }
}

class _OrdersListView extends StatelessWidget {
  final List<OrderModel> orders;

  const _OrdersListView({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "لا توجد طلبات هنا",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "تصفح المنتجات وابدأ التسوق الآن",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _OrderCardPro(order: orders[index]);
      },
    );
  }
}

class _OrderCardPro extends StatelessWidget {
  final OrderModel order;
  const _OrderCardPro({required this.order});

  @override
  Widget build(BuildContext context) {
    // إعداد متغيرات الحالة (أيقونة + لون + نص)
    Color statusColor;
    String statusText;
    IconData statusIcon;
    Color bgColor;

    switch (order.status.toLowerCase()) {
      case 'delivered':
        statusColor = const Color(0xFF27AE60); // أخضر احترافي
        statusText = "تم التوصيل";
        statusIcon = Icons.check_circle_outline;
        bgColor = const Color(0xFFEAFAF1);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFEB5757); // أحمر ناعم
        statusText = "ملغي";
        statusIcon = Icons.cancel_outlined;
        bgColor = const Color(0xFFFDECEC);
        break;
      case 'shipped':
        statusColor = const Color(0xFF2D9CDB); // أزرق
        statusText = "في الطريق";
        statusIcon = Icons.local_shipping_outlined;
        bgColor = const Color(0xFFEBF5FB);
        break;
      default:
        statusColor = const Color(0xFFF2994A); // برتقالي
        statusText = "قيد التجهيز";
        statusIcon = Icons.inventory_2_outlined;
        bgColor = const Color(0xFFFEF5E7);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. رأس الكارت (Header)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // أيقونة الحالة مع الخلفية
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),

                // رقم الطلب والتاريخ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // استخدام DateFormat لتنسيق التاريخ بشكل جميل
                        // تأكد من استيراد intl وإذا التاريخ String حوله لـ DateTime
                        order.date.length >= 10
                            ? order.date.substring(0, 10)
                            : order.date,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // رقم الطلب
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    "#${order.orderNumber}",
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // 2. محتوى المنتجات (Products Carousel)
          InkWell(
            onTap: () => _navigateToDetails(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // صور المنتجات (عرض أفقي)
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            order.items.length > 4 ? 4 : order.items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          // إذا كان هناك أكثر من 4 منتجات، اعرض "+X" في العنصر الأخير
                          if (index == 3 && order.items.length > 4) {
                            return _MoreItemsBadge(
                              count: order.items.length - 3,
                            );
                          }
                          return _ProductThumbnail(
                            imageUrl: order.items[index].productImage,
                          );
                        },
                      ),
                    ),
                  ),

                  // السهم للدلالة على القابلية للضغط
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // 3. التذييل (Footer) - السعر والإجراء
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الإجمالي",
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${order.totalPrice} ر.س",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900, // خط عريض جداً للأرقام
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                // زر "التفاصيل"
                ElevatedButton(
                  onPressed: () => _navigateToDetails(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.black, // أسود للفخامة (أو لون البراند)
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "التفاصيل",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => OrderDetailsScreen(orderId: order.id, initialOrder: order),
      ),
    );
  }
}

// ويدجت لعرض صورة المنتج بشكل أنيق
class _ProductThumbnail extends StatelessWidget {
  final String imageUrl;
  const _ProductThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder:
              (context, url) => Container(
                color: Colors.grey[100],
                child: const Icon(Icons.image, size: 20, color: Colors.grey),
              ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}

// ويدجت لعرض "+3" مثلاً إذا كانت المنتجات كثيرة
class _MoreItemsBadge extends StatelessWidget {
  final int count;
  const _MoreItemsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        "+$count",
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
