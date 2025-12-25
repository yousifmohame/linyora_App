import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ (أضف intl: ^0.18.0 في pubspec)
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/order_model.dart';
import '../services/order_service.dart';
import 'order_details_screen.dart'; // سننشئها في الخطوة التالية

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
    final orders = await _orderService.getMyOrders();
    if (mounted) {
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    }
  }

  // فلترة الطلبات حسب التبويب
  List<OrderModel> _getOrdersByStatus(String statusFilter) {
    if (statusFilter == 'all') return _allOrders;
    // هنا نفترض أن الحالات في الباك إند هي: pending, processing, shipped, delivered, cancelled
    return _allOrders
        .where((o) => o.status.toLowerCase() == statusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "طلباتي",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // للسماح بالتمرير إذا كانت التبويبات كثيرة
          labelColor: const Color(0xFFF105C6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFF105C6),
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
                  _buildOrdersList(_getOrdersByStatus('all')),
                  _buildOrdersList(
                    _getOrdersByStatus('processing'),
                  ), // أو pending
                  _buildOrdersList(_getOrdersByStatus('shipped')),
                  _buildOrdersList(_getOrdersByStatus('delivered')),
                  _buildOrdersList(_getOrdersByStatus('cancelled')),
                ],
              ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 10),
            const Text(
              "لا توجد طلبات في هذه القائمة",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _OrderCard(order: orders[index]);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    // تحديد لون الحالة
    Color statusColor;
    String statusText;
    switch (order.status.toLowerCase()) {
      case 'delivered':
        statusColor = Colors.green;
        statusText = "تم التوصيل";
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = "ملغي";
        break;
      case 'shipped':
        statusColor = Colors.blue;
        statusText = "تم الشحن";
        break;
      default:
        statusColor = Colors.orange;
        statusText = "قيد التجهيز";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => OrderDetailsScreen(
                  orderId: order.id, // الضروري لجلب البيانات الحديثة
                  initialOrder: order, // الاختياري للعرض الفوري
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // السطر الأول: رقم الطلب والتاريخ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "طلب ${order.orderNumber}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  // التحقق: إذا كان النص أطول من 10 أحرف نقصه، وإلا نعرضه كما هو
                  order.date.length >= 10
                      ? order.date.substring(0, 10)
                      : order.date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 20),

            // السطر الثاني: الحالة وعدد المنتجات
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "${order.items.length} منتجات",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // السطر الثالث: الإجمالي والصور المصغرة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "الإجمالي",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      "${order.totalPrice} ر.س",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFF105C6),
                      ),
                    ),
                  ],
                ),
                // عرض صور مصغرة لأول 3 منتجات
                Row(
                  children:
                      order.items.take(3).map((item) {
                        return Container(
                          margin: const EdgeInsets.only(left: 5),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                item.productImage,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
