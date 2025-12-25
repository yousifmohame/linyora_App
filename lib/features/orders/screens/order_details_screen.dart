import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/order_model.dart';
import '../services/order_service.dart'; // استدعاء السيرفس

class OrderDetailsScreen extends StatefulWidget {
  final int orderId; // نمرر الـ ID فقط أو الموديل المبدئي
  final OrderModel?
  initialOrder; // (اختياري) لعرض البيانات فوراً بينما يتم التحميل

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
    // إذا كان لدينا بيانات مبدئية نعرضها فوراً
    if (widget.initialOrder != null) {
      _order = widget.initialOrder;
    }
    // ثم نجلب البيانات الحديثة من السيرفر (مثل useEffect)
    _fetchOrderDetails();
  }

  // هذه الدالة تعادل fetchOrder في React
  Future<void> _fetchOrderDetails() async {
    setState(() => _isLoading = true);

    final orderDetails = await _orderService.getOrderDetails(widget.orderId);

    if (mounted) {
      setState(() {
        if (orderDetails != null) {
          _order = orderDetails;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _order != null ? "طلب رقم ${_order!.orderNumber}" : "تفاصيل الطلب",
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body:
          _isLoading && _order == null
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF105C6)),
              )
              : _order == null
              ? const Center(child: Text("تعذر تحميل تفاصيل الطلب"))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. ملخص الحالة
                    _buildInfoCard(
                      children: [
                        _buildRow(
                          "رقم الطلب",
                          _order!.orderNumber,
                          isBold: true,
                        ),
                        _buildRow(
                          "تاريخ الطلب",
                          // التحقق من الطول قبل القص لتجنب الخطأ
                          (_order!.date.length >= 10)
                              ? _order!.date.substring(0, 10)
                              : _order!.date,
                        ),
                        _buildRow(
                          "حالة الطلب",
                          _order!.status,
                          color: const Color(0xFFF105C6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. المنتجات
                    const Text(
                      "المنتجات",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _order!.items.length,
                      itemBuilder: (context, index) {
                        final item = _order!.items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: item.productImage,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorWidget:
                                      (context, url, error) =>
                                          const Icon(Icons.image_not_supported),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "الكمية: ${item.quantity}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${item.price} ر.س",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // 3. ملخص الدفع
                    _buildInfoCard(
                      children: [
                        _buildRow(
                          "المجموع الفرعي",
                          "${_order!.totalPrice} ر.س",
                        ),
                        _buildRow(
                          "الشحن",
                          "0.00 ر.س",
                        ), // يمكن جلب قيمة الشحن من الموديل إذا توفرت
                        const Divider(),
                        _buildRow(
                          "الإجمالي الكلي",
                          "${_order!.totalPrice} ر.س",
                          isBold: true,
                          color: const Color(0xFFF105C6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
