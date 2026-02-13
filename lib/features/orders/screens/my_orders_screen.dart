import 'dart:async'; // 1. استيراد للمؤقت
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/orders/screens/tracking_screen.dart';
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

  // 2. متغير للمؤقت
  Timer? _refreshTimer;

  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchOrders();

    // 3. بدء التحديث التلقائي كل 10 ثواني
    _startAutoRefresh();
  }

  @override
  void dispose() {
    // 4. إيقاف المؤقت عند الخروج لتوفير الموارد
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // نمرر true لكي لا يظهر Loading Spinner ويزعج المستخدم
      _fetchOrders(isBackground: true);
    });
  }

  // 5. تعديل الدالة لتقبل التحميل في الخلفية
  Future<void> _fetchOrders({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final orders = await _orderService.getMyOrders();
      // ترتيب الطلبات من الأحدث للأقدم
      orders.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _allOrders = orders;
          if (!isBackground) _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isBackground) {
        setState(() {
          _isLoading = false;
          _errorMessage = "تعذر تحميل الطلبات، اسحب للأسفل للتحديث";
        });
      }
    }
  }

  // 6. تحديث الفلتر ليتناسب مع الحالات الجديدة
  List<OrderModel> _getOrdersByStatus(String filterType) {
    if (filterType == 'all') return _allOrders;

    return _allOrders.where((order) {
      final status = order.status.toLowerCase();
      switch (filterType) {
        case 'active':
          return ['pending', 'processing'].contains(status);
        case 'shipped':
          return ['shipped'].contains(status);
        case 'completed':
          return ['completed'].contains(status);
        case 'cancelled':
          return ['cancelled'].contains(status);
        default:
          return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          "طلباتي",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        leading: const BackButton(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFF105C6),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFFF105C6),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Cairo',
          ),
          tabs: const [
            Tab(text: "الكل"),
            Tab(text: "نشط"), // pending + processing
            Tab(text: "في الطريق"), // shipped
            Tab(text: "مكتمل"), // completed
            Tab(text: "ملغية"), // cancelled
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
                    onRefresh: () => _fetchOrders(),
                  ),
                  _OrdersList(
                    orders: _getOrdersByStatus('active'),
                    onRefresh: () => _fetchOrders(),
                  ),
                  _OrdersList(
                    orders: _getOrdersByStatus('shipped'),
                    onRefresh: () => _fetchOrders(),
                  ),
                  _OrdersList(
                    orders: _getOrdersByStatus('completed'),
                    onRefresh: () => _fetchOrders(),
                  ),
                  _OrdersList(
                    orders: _getOrdersByStatus('cancelled'),
                    onRefresh: () => _fetchOrders(),
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
          Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _fetchOrders(),
            icon: const Icon(Icons.refresh),
            label: const Text("إعادة المحاولة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF105C6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "لا توجد طلبات هنا",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

  // 7. ✅ تحديث الألوان والنصوص لتطابق الموقع تماماً
  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'color': Colors.amber[800], // Amber-800
          'bg': Colors.amber[100], // Amber-100
          'text': 'قيد الانتظار',
          'icon': Icons.access_time_rounded, // Clock
        };
      case 'processing':
        return {
          'color': Colors.blue[800], // Blue-800
          'bg': Colors.blue[100], // Blue-100
          'text': 'قيد التنفيذ',
          'icon':
              Icons.cached_rounded, // RefreshCw (Cached is closest in Material)
        };
      case 'shipped':
        return {
          'color': Colors.indigo[800], // Indigo-800
          'bg': Colors.indigo[100], // Indigo-100
          'text': 'تم الشحن',
          'icon': Icons.local_shipping_rounded, // Truck
        };
      case 'completed':
        return {
          'color': Colors.green[800], // Green-800
          'bg': Colors.green[100], // Green-100
          'text': 'مكتمل',
          'icon': Icons.check_circle_outline_rounded, // CheckCircle
        };
      case 'cancelled':
        return {
          'color': Colors.red[800], // Red-800
          'bg': Colors.red[100], // Red-100
          'text': 'ملغي',
          'icon': Icons.cancel_outlined, // XCircle
        };
      default:
        // حالة افتراضية
        return {
          'color': Colors.grey[800],
          'bg': Colors.grey[200],
          'text': status,
          'icon': Icons.info_outline,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _getStatusStyle(order.status);

    String formattedDate;
    try {
      final date = DateTime.parse(order.date);
      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      formattedDate = order.date;
    }

    return GestureDetector(
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // 1. الشريط العلوي (رقم الطلب والحالة)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "طلب #${order.orderNumber}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
                      border: Border.all(
                        color: statusStyle['color'].withOpacity(0.2),
                      ), // إضافة حدود خفيفة مثل الكود الأصلي
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
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. المنتجات
            if (order.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 80,
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount:
                              order.items.length > 4 ? 4 : order.items.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            if (order.items.length > 4 && index == 3) {
                              return _MoreItemsBadge(
                                count: order.items.length - 3,
                              );
                            }
                            return _ProductImage(
                              imageUrl: order.items[index].productImage,
                            );
                          },
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
              ),

            // 3. الفوتر
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "الإجمالي",
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      Text(
                        "${order.totalPrice.toStringAsFixed(2)} ر.س",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (order.status.toLowerCase() == 'shipped')
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => OrderTrackingScreen(
                                    orderId: order.id, // ✅ نمرر الـ ID فقط
                                  ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo[800],
                          side: BorderSide(color: Colors.indigo.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "تتبع",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => OrderDetailsScreen(
                                orderId: order.id,
                                initialOrder: order,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "التفاصيل",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;
  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey[50]),
          errorWidget:
              (context, url, error) => const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey,
                size: 20,
              ),
        ),
      ),
    );
  }
}

class _MoreItemsBadge extends StatelessWidget {
  final int count;
  const _MoreItemsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "+$count",
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            "منتجات",
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      ),
    );
  }
}
