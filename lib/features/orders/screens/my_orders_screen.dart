import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // تأكد من إضافة intl في pubspec.yaml
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 5 تبويبات لتغطية كافة الحالات
    _tabController = TabController(length: 5, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderService.getMyOrders();
      // ترتيب الطلبات من الأحدث للأقدم
      orders.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "حدث خطأ أثناء جلب الطلبات، يرجى المحاولة مرة أخرى.";
        });
      }
    }
  }

  // دالة ذكية لفلترة الطلبات حسب التبويب
  List<OrderModel> _getOrdersByStatus(String filterType) {
    if (filterType == 'all') return _allOrders;

    return _allOrders.where((order) {
      final status = order.status.toLowerCase();
      switch (filterType) {
        case 'active': // قيد التنفيذ
          return [
            'pending',
            'processing',
            'confirmed',
            'packing',
          ].contains(status);
        case 'shipped': // تم الشحن
          return ['shipped', 'out_for_delivery', 'on_way'].contains(status);
        case 'completed': // مكتمل
          return ['delivered', 'completed'].contains(status);
        case 'cancelled': // ملغي/مرتجع
          return [
            'cancelled',
            'returned',
            'refunded',
            'rejected',
          ].contains(status);
        default:
          return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F6FA,
      ), // خلفية رمادية فاتحة جداً مريحة للعين
      appBar: AppBar(
        title: const Text(
          "طلباتي",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFF105C6),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFFF105C6),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ), // استخدم خط التطبيق
          tabs: const [
            Tab(text: "الكل"),
            Tab(text: "قيد التجهيز"),
            Tab(text: "في الطريق"),
            Tab(text: "مكتملة"),
            Tab(text: "ملغية/مسترجعة"),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF105C6)),
              )
              : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                controller: _tabController,
                children: [
                  _OrdersList(
                    orders: _getOrdersByStatus('all'),
                    onRefresh: _fetchOrders,
                  ),
                  _OrdersList(
                    orders: _getOrdersByStatus('active'),
                    onRefresh: _fetchOrders,
                  ),
                  _OrdersList(
                    orders: _getOrdersByStatus('shipped'),
                    onRefresh: _fetchOrders,
                  ),
                  _OrdersList(
                    orders: _getOrdersByStatus('completed'),
                    onRefresh: _fetchOrders,
                  ),
                  _OrdersList(
                    orders: _getOrdersByStatus('cancelled'),
                    onRefresh: _fetchOrders,
                  ),
                ],
              ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF105C6),
            ),
            child: const Text(
              "تحديث الصفحة",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderModel> orders;
  final Future<void> Function() onRefresh;

  const _OrdersList({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFFF105C6),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "لا توجد طلبات في هذه القائمة",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFF105C6),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _BigStoreOrderCard(order: orders[index]);
        },
      ),
    );
  }
}

class _BigStoreOrderCard extends StatelessWidget {
  final OrderModel order;

  const _BigStoreOrderCard({required this.order});

  // تحديد ستايل الحالة بناءً على النص
  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return {
          'color': const Color(0xFF27AE60),
          'bg': const Color(0xFFE8F8F5),
          'text': 'تم التوصيل',
          'icon': Icons.check_circle,
        };
      case 'shipped':
      case 'on_way':
        return {
          'color': const Color(0xFF2980B9),
          'bg': const Color(0xFFEBF5FB),
          'text': 'في الطريق إليك',
          'icon': Icons.local_shipping,
        };
      case 'cancelled':
      case 'rejected':
        return {
          'color': const Color(0xFFC0392B),
          'bg': const Color(0xFFFADBD8),
          'text': 'ملغي',
          'icon': Icons.cancel,
        };
      case 'processing':
      case 'pending':
      default:
        return {
          'color': const Color(0xFFF39C12),
          'bg': const Color(0xFFFEF9E7),
          'text': 'قيد التجهيز',
          'icon': Icons.inventory_2,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _getStatusStyle(order.status);

    // ✅ إصلاح مشكلة التاريخ هنا
    String dateFormatted;
    try {
      // محاولة تحويل النص إلى تاريخ وتنسيقه
      final DateTime parsedDate = DateTime.parse(order.date);
      dateFormatted = DateFormat('dd MMM yyyy - hh:mm a').format(parsedDate);
    } catch (e) {
      // في حال الفشل (التنسيق غير صحيح)، نعرض النص كما جاء من السيرفر
      dateFormatted = order.date;
    }

    return Container(
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
        children: [
          // 1. رأس الكارت
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "طلب #${order.orderNumber}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatted, // ✅ استخدام المتغير الآمن
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusStyle['bg'],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusStyle['icon'],
                        size: 14,
                        color: statusStyle['color'],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusStyle['text'],
                        style: TextStyle(
                          color: statusStyle['color'],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // 2. صور المنتجات
          InkWell(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => OrderDetailsScreen(
                          orderId: order.id,
                          initialOrder: order,
                        ),
                  ),
                ),
            child: Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          order.items.length > 4 ? 4 : order.items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index == 3 && order.items.length > 4) {
                          return _MoreItemsBadge(count: order.items.length - 3);
                        }
                        return _ProductImage(
                          imageUrl: order.items[index].productImage,
                        );
                      },
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // 3. الجزء السفلي
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "المجموع الكلي",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      "${order.totalPrice} ر.س",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // زر تتبع الشحنة
                if ([
                  'shipped',
                  'out_for_delivery',
                ].contains(order.status.toLowerCase()))
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("تتبع الشحنة"),
                  ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => OrderDetailsScreen(
                                orderId: order.id,
                                initialOrder: order,
                              ),
                        ),
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text("التفاصيل"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ويدجت لعرض صورة المنتج
class _ProductImage extends StatelessWidget {
  final String imageUrl;
  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey[50]),
          errorWidget:
              (context, url, error) =>
                  const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      ),
    );
  }
}

// ويدجت للمنتجات الزائدة (+2)
class _MoreItemsBadge extends StatelessWidget {
  final int count;
  const _MoreItemsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
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
