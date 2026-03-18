import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

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
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
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
                title: Text(
                  l10n.incomingOrders,
                  style: const TextStyle(color: Colors.black),
                ), // ✅ عنوان اختياري (مترجم)
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_orders.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.noOrdersCurrentlyMsg,
                          style: const TextStyle(color: Colors.grey),
                        ), // ✅ مترجم
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildOrderCard(
                      _orders[index],
                      l10n,
                    ), // ✅ تمرير الترجمة
                    childCount: _orders.length,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(SupplierOrder order, AppLocalizations l10n) {
    String langCode =
        Localizations.localeOf(context).languageCode; // لضبط لغة التاريخ

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
                  _buildStatusBadge(order.orderStatus, l10n), // ✅ تمرير الترجمة
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
                          l10n.quantityAndCustomerMsg(
                            order.quantity.toString(),
                            order.customerName,
                          ), // ✅ دالة مولدة بديلة لـ replaceAll
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
                        "${order.totalCost} ${l10n.currencySAR}", // ✅ عملة مترجمة
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy/MM/dd', langCode).format(
                          DateTime.parse(order.orderDate),
                        ), // ✅ تنسيق التاريخ
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

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = Colors.amber;
        text = l10n.pending;
        break;
      case 'processing':
        color = Colors.blue;
        text = l10n.processingOrder;
        break;
      case 'shipped':
        color = Colors.indigo;
        text = l10n.shipped;
        break;
      case 'completed':
        color = Colors.green;
        text = l10n.completed;
        break;
      case 'cancelled':
        color = Colors.red;
        text = l10n.cancelled;
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
// النافذة المنبثقة للتفاصيل (Modal)
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
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _updateStatus(AppLocalizations l10n) async {
    setState(() => _isUpdating = true);
    try {
      await widget.service.updateOrderStatus(widget.orderId, _selectedStatus);
      widget.onUpdate();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.statusUpdatedSuccessMsg),
          ), // ✅ مترجم (سابقاً)
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
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
                      "${l10n.orderHashPrefix}${widget.orderId}", // ✅ مترجم ومدمج
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
                        _buildInfoCard(
                          l10n.customerInfoLabel, // ✅ مترجم (سابقاً)
                          Icons.person,
                          Colors.blue,
                          [
                            _infoRow(Icons.person, _details!.customer.name),
                            _infoRow(Icons.email, _details!.customer.email),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          l10n.shippingAddressLabel, // ✅ مترجم (سابقاً)
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
                        _buildInfoCard(
                          l10n.productsLabel, // ✅ مترجم (سابقاً)
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
                              Text(
                                l10n.updateStatusLabel, // ✅ مترجم (سابقاً)
                                style: const TextStyle(
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
                                items: [
                                  DropdownMenuItem(
                                    value: 'pending',
                                    child: Text(l10n.pending),
                                  ),
                                  DropdownMenuItem(
                                    value: 'processing',
                                    child: Text(l10n.processingOrder),
                                  ),
                                  DropdownMenuItem(
                                    value: 'shipped',
                                    child: Text(l10n.shipped),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text(l10n.completed),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cancelled',
                                    child: Text(l10n.cancelled),
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
                                  onPressed:
                                      _isUpdating
                                          ? null
                                          : () => _updateStatus(
                                            l10n,
                                          ), // ✅ تمرير l10n
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
                                          : Text(
                                            l10n.saveChangesBtn,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ), // ✅ مترجم (سابقاً)
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
