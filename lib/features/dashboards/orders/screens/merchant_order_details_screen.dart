import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للنسخ
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/merchant_order_details_model.dart';
import '../services/merchant_order_service.dart';

class MerchantOrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const MerchantOrderDetailsScreen({Key? key, required this.orderId})
    : super(key: key);

  @override
  State<MerchantOrderDetailsScreen> createState() =>
      _MerchantOrderDetailsScreenState();
}

class _MerchantOrderDetailsScreenState
    extends State<MerchantOrderDetailsScreen> {
  final MerchantOrderService _orderService = MerchantOrderService();
  MerchantOrderDetails? _orderDetails;
  bool _isLoading = true;
  String? _error;

  // حالات الطلب المتاحة للتغيير
  final List<String> _statuses = [
    'pending',
    'processing',
    'shipped',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final data = await _orderService.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _orderDetails = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    // تأكيد التغيير
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text('تغيير حالة الطلب'),
            content: Text(
              'هل أنت متأكد من تغيير الحالة إلى ${_translateStatus(newStatus)}؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF105C6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'تأكيد',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      // إظهار Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const Center(
              child: CircularProgressIndicator(color: Color(0xFFF105C6)),
            ),
      );

      await _orderService.updateOrderStatus(widget.orderId, newStatus);

      if (mounted) {
        Navigator.pop(context); // إغلاق Loading
        _fetchDetails(); // تحديث البيانات
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الحالة بنجاح ✅'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // إغلاق Loading
        String errorMsg = 'فشل التحديث';
        // معالجة خطأ 403 القادم من السيرفر كاحتياط
        if (e.toString().contains('403')) {
          errorMsg = 'غير مسموح بتعديل هذا الطلب (دروب شيبينج)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'حسناً',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم النسخ للحافظة'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // خلفية هادئة وعصرية
      appBar: AppBar(
        title: Text(
          'طلب #${widget.orderId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF105C6)),
              )
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text('حدث خطأ: $_error'),
                    TextButton(
                      onPressed: _fetchDetails,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. بطاقة الحالة والإجراءات
                    _buildHeaderCard(),
                    const SizedBox(height: 16),

                    // 2. قائمة المنتجات
                    _buildItemsCard(),
                    const SizedBox(height: 16),

                    // 3. معلومات العميل
                    _buildCustomerCard(),
                    const SizedBox(height: 16),

                    // 4. ملخص الدفع والشحن
                    _buildPaymentAndShippingCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
    );
  }

  // --- البطاقات ---

  Widget _buildHeaderCard() {
    final status = _orderDetails!.info.status;

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تاريخ الطلب: ${_orderDetails!.info.createdAt}', // تنسيق التاريخ
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(status).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _translateStatus(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'تحديث الحالة:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          // إذا كان دروب شيبينج، نخفي أزرار التحديث أو نظهر رسالة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _statuses.map((s) {
                    bool isSelected = s == status;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(_translateStatus(s)),
                        selected: isSelected,
                        onSelected:
                            isSelected ? null : (selected) => _changeStatus(s),
                        backgroundColor: Colors.grey[50],
                        selectedColor: _getStatusColor(s).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? _getStatusColor(s) : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? _getStatusColor(s)
                                  : Colors.grey.shade300,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    final info = _orderDetails!.info;
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                'معلومات العميل',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFF105C6).withOpacity(0.1),
                child: Text(
                  info.customerName[0].toUpperCase(),
                  style: const TextStyle(color: Color(0xFFF105C6)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    info.customerEmail,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone_outlined,
            'رقم الهاتف',
            info.customerPhone ?? 'غير متوفر',
            isCopyable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                'المنتجات (${_orderDetails!.items.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orderDetails!.items.length,
            separatorBuilder: (ctx, i) => const Divider(height: 24),
            itemBuilder: (ctx, index) {
              final item = _orderDetails!.items[index];
              return Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: item.image ?? '',
                        fit: BoxFit.cover,
                        placeholder:
                            (c, u) => Container(color: Colors.grey[100]),
                        errorWidget:
                            (c, u, e) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'الكمية: ${item.quantity}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(item.price * item.quantity).toStringAsFixed(2)} ر.س',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAndShippingCard() {
    final info = _orderDetails!.info;
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                'الشحن والدفع',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),

          if (info.shippingAddress != null) ...[
            const Text(
              "عنوان الشحن",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(info.shippingAddress!, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "طريقة الدفع",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.credit_card,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          info.paymentMethod,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "حالة الدفع",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (info.paymentStatus == 'paid'
                                ? Colors.green
                                : Colors.red)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        info.paymentStatus == 'paid' ? 'مدفوع' : 'غير مدفوع',
                        style: TextStyle(
                          color:
                              info.paymentStatus == 'paid'
                                  ? Colors.green
                                  : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإجمالي الكلي',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${info.totalAmount.toStringAsFixed(2)} ر.س',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFFF105C6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (isCopyable)
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
            onPressed: () => _copyToClipboard(value),
            tooltip: "نسخ",
          ),
      ],
    );
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد التجهيز';
      case 'shipped':
        return 'تم الشحن';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      case 'shipped':
        return Colors.indigo;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
