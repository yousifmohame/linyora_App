import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import 'package:linyora_project/features/dashboards/orders/screens/merchant_order_details_screen.dart';
import '../models/merchant_order_model.dart';
import '../services/merchant_order_service.dart';

class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen> {
  final MerchantOrderService _orderService = MerchantOrderService();
  List<MerchantOrderSummary> _allOrders = [];
  List<MerchantOrderSummary> _filteredOrders = [];

  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderService.getOrders();
      if (mounted) {
        setState(() {
          _allOrders = orders;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders =
          _allOrders.filter((order) {
            final matchesSearch =
                order.customerName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                order.orderId.toString().contains(_searchQuery);

            final matchesStatus =
                _statusFilter == 'all' || order.orderStatus == _statusFilter;

            return matchesSearch && matchesStatus;
          }).toList();
    });
  }

  Map<String, dynamic> _calculateStats() {
    return {
      'total': _allOrders.length,
      'pending': _allOrders.where((o) => o.orderStatus == 'pending').length,
      'completed': _allOrders.where((o) => o.orderStatus == 'completed').length,
      'cancelled': _allOrders.where((o) => o.orderStatus == 'cancelled').length,
      'revenue': _allOrders.fold(0.0, (sum, o) => sum + o.totalAmount),
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n.ordersManagementTitle), // ✅ مترجم
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatCard(
                    l10n.all,
                    stats['total'].toString(),
                    Colors.blue,
                    Icons.shopping_bag,
                  ), // ✅ مترجم
                  const SizedBox(width: 8),
                  _buildStatCard(
                    l10n.pending,
                    stats['pending'].toString(),
                    Colors.amber,
                    Icons.hourglass_top,
                  ), // ✅ مترجم
                  const SizedBox(width: 8),
                  _buildStatCard(
                    l10n.completed,
                    stats['completed'].toString(),
                    Colors.green,
                    Icons.check_circle,
                  ), // ✅ مترجم
                  const SizedBox(width: 8),
                  _buildStatCard(
                    l10n.cancelled,
                    stats['cancelled'].toString(),
                    Colors.red,
                    Icons.cancel,
                  ), // ✅ مترجم
                  const SizedBox(width: 8),
                  _buildStatCard(
                    l10n.profits,
                    '${stats['revenue'].toStringAsFixed(0)} ${l10n.currencySAR}',
                    Colors.purple,
                    Icons.attach_money,
                  ), // ✅ مترجم
                ],
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                hintText: l10n.searchOrderOrCustomerHint, // ✅ مترجم
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                _searchQuery = val;
                _applyFilters();
              },
            ),

            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(l10n.all, 'all'), // ✅ مترجم
                  const SizedBox(width: 8),
                  _buildFilterChip(l10n.pending, 'pending'), // ✅ مترجم
                  const SizedBox(width: 8),
                  _buildFilterChip(l10n.completed, 'completed'), // ✅ مترجم
                  const SizedBox(width: 8),
                  _buildFilterChip(l10n.cancelled, 'cancelled'), // ✅ مترجم
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredOrders.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    l10n.noMatchingOrdersMsg, // ✅ مترجم
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredOrders.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder:
                    (ctx, index) => _buildOrderCard(
                      _filteredOrders[index],
                      l10n,
                    ), // ✅ تمرير l10n
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _statusFilter = value;
            _applyFilters();
          });
        }
      },
      selectedColor: const Color(0xFFF43F5E).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFF43F5E) : Colors.black,
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildOrderCard(MerchantOrderSummary order, AppLocalizations l10n) {
    String langCode = Localizations.localeOf(context).languageCode;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusBadge(order.orderStatus, l10n), // ✅ تمرير l10n
              ],
            ),
            const Divider(height: 24),

            _buildInfoRow(Icons.person, order.customerName),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.shopping_bag,
              order.productsSummary,
              isProduct: true,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              DateFormat(
                'yyyy-MM-dd',
                langCode,
              ).format(order.orderDate), // ✅ تنسيق التاريخ
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} ${l10n.currencySAR}', // ✅ عملة مترجمة
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFF43F5E),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => MerchantOrderDetailsScreen(
                              orderId: order.orderId,
                            ),
                      ),
                    ).then((_) => _fetchOrders());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFF43F5E),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFF43F5E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(l10n.viewDetailsBtn), // ✅ مترجم
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isProduct = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isProduct ? Colors.black87 : Colors.grey[700],
              fontWeight: isProduct ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: isProduct ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    Color color;
    String text;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        text = l10n.completed;
        break;
      case 'pending':
        color = Colors.amber;
        text = l10n.pending;
        break;
      case 'cancelled':
        color = Colors.red;
        text = l10n.cancelled;
        break;
      case 'shipped':
        color = Colors.blue;
        text = l10n.shipped;
        break;
      case 'processing':
        color = Colors.orange;
        text = l10n.processingOrder;
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
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

extension ListFilter<T> on List<T> {
  List<T> filter(bool Function(T) test) {
    final List<T> result = [];
    for (var element in this) {
      if (test(element)) result.add(element);
    }
    return result;
  }
}
