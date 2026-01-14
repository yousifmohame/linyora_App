import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import 'package:linyora_project/features/supplier/orders/models/supplier_order_models.dart';
import 'package:linyora_project/features/supplier/orders/services/supplier_orders_service.dart';

class SupplierOrdersScreen extends StatefulWidget {
  const SupplierOrdersScreen({Key? key}) : super(key: key);

  @override
  State<SupplierOrdersScreen> createState() => _SupplierOrdersScreenState();
}

class _SupplierOrdersScreenState extends State<SupplierOrdersScreen> {
  final SupplierOrdersService _service = SupplierOrdersService();
  List<SupplierOrder> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final data = await _service.getOrders();
      if (mounted)
        setState(() {
          _orders = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // فتح نافذة التفاصيل
  void _openOrderDetails(int orderId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _OrderDetailsModal(
            orderId: orderId,
            service: _service,
            onUpdate: _fetchOrders,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          // الخلفية (Blur Circles)
          Positioned(
            top: -50,
            right: -50,
            child: _blurCircle(Colors.blue.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _blurCircle(Colors.purple.withOpacity(0.15)),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                iconTheme: const IconThemeData(color: Colors.black),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_orders.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "لا توجد طلبات حالياً",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildOrderCard(_orders[index]),
                    childCount: _orders.length,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(SupplierOrder order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.blue.withOpacity(0.1),
      child: InkWell(
        onTap: () => _openOrderDetails(order.orderId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "#${order.orderId}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusBadge(order.orderStatus),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "الكمية: ${order.quantity} | العميل: ${order.customerName}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${order.totalCost} ر.س",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'yyyy/MM/dd',
                        ).format(DateTime.parse(order.orderDate)),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = Colors.amber;
        text = 'قيد الانتظار';
        break;
      case 'processing':
        color = Colors.blue;
        text = 'جاري التجهيز';
        break;
      case 'shipped':
        color = Colors.indigo;
        text = 'تم الشحن';
        break;
      case 'completed':
        color = Colors.green;
        text = 'مكتمل';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'ملغي';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _blurCircle(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// -----------------------------------------------------------------------------
// النافذة المنبثقة للتفاصيل (Modal) - نفس تصميم React
// -----------------------------------------------------------------------------
class _OrderDetailsModal extends StatefulWidget {
  final int orderId;
  final SupplierOrdersService service;
  final VoidCallback onUpdate;

  const _OrderDetailsModal({
    required this.orderId,
    required this.service,
    required this.onUpdate,
  });

  @override
  State<_OrderDetailsModal> createState() => _OrderDetailsModalState();
}

class _OrderDetailsModalState extends State<_OrderDetailsModal> {
  OrderDetails? _details;
  bool _isLoading = true;
  bool _isUpdating = false;
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final data = await widget.service.getOrderDetails(widget.orderId);
      if (mounted)
        setState(() {
          _details = data;
          _selectedStatus = data.orderStatus;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) Navigator.pop(context); // إغلاق إذا فشل
    }
  }

  Future<void> _updateStatus() async {
    setState(() => _isUpdating = true);
    try {
      await widget.service.updateOrderStatus(widget.orderId, _selectedStatus);
      widget.onUpdate(); // تحديث القائمة الخلفية
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم تحديث الحالة ✅")));
      }
    } catch (e) {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue, Colors.indigo]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      "طلب #${widget.orderId}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 1. معلومات العميل والشحن
                        _buildInfoCard(
                          "معلومات العميل",
                          Icons.person,
                          Colors.blue,
                          [
                            _infoRow(Icons.person, _details!.customer.name),
                            _infoRow(Icons.email, _details!.customer.email),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          "عنوان الشحن",
                          Icons.local_shipping,
                          Colors.indigo,
                          [
                            _infoRow(
                              Icons.person,
                              _details!.shippingAddress.name,
                            ),
                            _infoRow(
                              Icons.location_on,
                              _details!.shippingAddress.address,
                            ),
                            _infoRow(
                              Icons.map,
                              "${_details!.shippingAddress.city}, ${_details!.shippingAddress.country}",
                            ),
                            _infoRow(
                              Icons.phone,
                              _details!.shippingAddress.phone,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 2. المنتجات
                        _buildInfoCard(
                          "المنتجات",
                          Icons.inventory_2,
                          Colors.green,
                          _details!.items
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item.name} (${item.color})",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${item.quantity} x ${item.totalCost}",
                                        style: const TextStyle(
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),

                        // 3. تحديث الحالة
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "تحديث الحالة",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'pending',
                                    child: Text("قيد الانتظار"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'processing',
                                    child: Text("جاري التجهيز"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'shipped',
                                    child: Text("تم الشحن"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text("مكتمل"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cancelled',
                                    child: Text("ملغي"),
                                  ),
                                ],
                                onChanged:
                                    (val) =>
                                        setState(() => _selectedStatus = val!),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isUpdating ? null : _updateStatus,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child:
                                      _isUpdating
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            "حفظ التغييرات",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.05), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
