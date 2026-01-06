import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/order_model.dart';
import '../services/order_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final OrderModel? initialOrder;

  const OrderDetailsScreen({Key? key, required this.orderId, this.initialOrder})
    : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService();
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _order = widget.initialOrder;
      _isLoading = false;
    }
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    // إذا لم يكن لدينا بيانات مبدئية، نظهر التحميل
    if (widget.initialOrder == null) {
      setState(() => _isLoading = true);
    }

    try {
      final orderDetails = await _orderService.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          if (orderDetails != null) {
            _order = orderDetails;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // خلفية رمادية فاتحة جداً عصرية
      appBar: AppBar(
        title: const Text(
          "تفاصيل الطلب",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        actions: [
          // زر المساعدة (شائع في التطبيقات الكبرى)
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body:
          _isLoading && _order == null
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF105C6)),
              )
              : _order == null
              ? _buildErrorState()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. رأس الصفحة (رقم الطلب والتاريخ والحالة)
                    _buildHeaderSection(),
                    const SizedBox(height: 20),

                    // 2. قسم المنتجات
                    const Text(
                      "محتويات الشحنة",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildProductsList(),
                    const SizedBox(height: 20),

                    // 3. قسم الدفع (الفاتورة)
                    _buildPaymentSummary(),

                    const SizedBox(height: 30),

                    // 4. أزرار الإجراءات
                    _buildActionButtons(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
    );
  }

  // --- Widgets ---

  Widget _buildHeaderSection() {
    // تحديد اللون والأيقونة بناءً على الحالة
    Color statusColor;
    IconData statusIcon;
    String statusText = _order!.status;

    switch (_order!.status.toLowerCase()) {
      case 'delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = "تم التوصيل";
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = "ملغي";
        break;
      case 'shipped':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        statusText = "تم الشحن";
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.inventory_2;
        statusText = "قيد التجهيز";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "رقم الطلب: ${_order!.orderNumber}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "تاريخ الطلب",
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _order!.date.length >= 10
                        ? _order!.date.substring(0, 10)
                        : _order!.date,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              // يمكن إضافة وقت التوصيل المتوقع هنا
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _order!.items.length,
        separatorBuilder: (ctx, index) => const Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final item = _order!.items[index];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة المنتج
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.productImage,
                      fit: BoxFit.cover,
                      errorWidget:
                          (context, url, error) => const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // التفاصيل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "الكمية: ${item.quantity}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // السعر
                Text(
                  "${(item.price * item.quantity).toStringAsFixed(0)} ر.س",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentSummary() {
    // حساب المجموع الفرعي من المنتجات (إذا لم يوفره الباك إند)
    // double subTotal = _order!.items.fold(0, (sum, item) => sum + (item.price * item.quantity));
    // أو نستخدم الحساب العكسي: الإجمالي - الشحن
    double subTotal = _order!.totalPrice - _order!.shippingCost;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ملخص الدفع",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 15),
          _buildSummaryRow("المجموع الفرعي", subTotal),
          const SizedBox(height: 10),
          _buildSummaryRow(
            "رسوم الشحن",
            _order!.shippingCost,
            isGreen: _order!.shippingCost == 0,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "الإجمالي الكلي",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "${_order!.totalPrice.toStringAsFixed(2)} ر.س",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFFF105C6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, double amount, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          amount == 0 ? "مجاني" : "${amount.toStringAsFixed(2)} ر.س",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isGreen ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // وظيفة تتبع الشحنة (يمكن ربطها بشركة الشحن مستقبلاً)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("سيتم تفعيل التتبع قريباً")),
          );
        },
        icon: const Icon(Icons.location_on_outlined, size: 18),
        label: const Text(
          "تتبع الشحنة",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("عذراً، حدث خطأ في تحميل البيانات"),
          TextButton(
            onPressed: _fetchOrderDetails,
            child: const Text(
              "إعادة المحاولة",
              style: TextStyle(color: Color(0xFFF105C6)),
            ),
          ),
        ],
      ),
    );
  }
}
