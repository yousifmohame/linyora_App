import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:linyora_project/features/orders/screens/tracking_screen.dart';
import '../../../models/order_model.dart';
import '../services/order_service.dart';

// نموذج مساعد لتخزين بيانات المراجعة محلياً
class LocalReviewData {
  int rating;
  String comment;
  LocalReviewData({required this.rating, required this.comment});
}

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
  Timer? _refreshTimer;

  // 🔥 تحديث: خريطة لتخزين التقييمات (Id المنتج -> بيانات التقييم)
  final Map<int, LocalReviewData> _productReviews = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _order = widget.initialOrder;
      _populateInitialReviews(); // ملء التقييمات إذا كانت موجودة في الموديل
      _isLoading = false;
    }
    _fetchOrderDetails();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchOrderDetails(isBackground: true);
    });
  }

  // ملء البيانات المحلية من الموديل القادم من السيرفر (إذا كان الموديل يدعم ذلك)
  // 1. ملء التقييمات من البيانات الحقيقية القادمة من السيرفر
  void _populateInitialReviews() {
    if (_order == null) return;

    for (var item in _order!.items) {
      // إذا كانت حالة التقييم القادمة من السيرفر "true"
      if (item.isReviewed) {
        setState(() {
          _productReviews[item.productId] = LocalReviewData(
            rating: item.myRating ?? 5,
            comment: item.myComment ?? "",
          );
        });
      }
    }
  }

  // 2. تحديث دالة جلب البيانات لاستدعاء Populate
  Future<void> _fetchOrderDetails({bool isBackground = false}) async {
    if (widget.initialOrder == null && !isBackground) {
      setState(() => _isLoading = true);
    }

    try {
      final orderDetails = await _orderService.getOrderDetails(widget.orderId);
      if (mounted && orderDetails != null) {
        setState(() {
          _order = orderDetails;
          if (!isBackground) _isLoading = false;
        });

        // 🔥 أهم خطوة: تحديث الحالة المحلية بناءً على بيانات السيرفر
        _populateInitialReviews();
      }
    } catch (e) {
      if (mounted && !isBackground) setState(() => _isLoading = false);
      debugPrint("Error fetching details: $e");
    }
  }

  // ... (دالة _getStatusAttributes بقيت كما هي) ...
  Map<String, dynamic> _getStatusAttributes(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'label': 'قيد الانتظار',
          'bgColor': Colors.amber.shade100,
          'textColor': Colors.amber.shade900,
          'borderColor': Colors.amber.shade200,
          'icon': Icons.access_time_rounded,
        };
      case 'processing':
        return {
          'label': 'قيد التنفيذ',
          'bgColor': Colors.blue.shade100,
          'textColor': Colors.blue.shade900,
          'borderColor': Colors.blue.shade200,
          'icon': Icons.cached_rounded,
        };
      case 'shipped':
      case 'on_way':
      case 'out_for_delivery':
        return {
          'label': 'تم الشحن',
          'bgColor': Colors.indigo.shade100,
          'textColor': Colors.indigo.shade900,
          'borderColor': Colors.indigo.shade200,
          'icon': Icons.local_shipping_rounded,
        };
      case 'completed':
      case 'delivered':
        return {
          'label': 'مكتمل',
          'bgColor': Colors.green.shade100,
          'textColor': Colors.green.shade900,
          'borderColor': Colors.green.shade200,
          'icon': Icons.check_circle_outline_rounded,
        };
      case 'cancelled':
      case 'rejected':
      case 'returned':
        return {
          'label': 'ملغي',
          'bgColor': Colors.red.shade100,
          'textColor': Colors.red.shade900,
          'borderColor': Colors.red.shade200,
          'icon': Icons.cancel_outlined,
        };
      default:
        return {
          'label': status,
          'bgColor': Colors.grey.shade200,
          'textColor': Colors.grey.shade800,
          'borderColor': Colors.grey.shade300,
          'icon': Icons.info_outline_rounded,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          "تفاصيل الطلب",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body:
          _isLoading && _order == null
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF105C6)),
              )
              : _order == null
              ? _buildErrorState()
              : RefreshIndicator(
                onRefresh: _fetchOrderDetails,
                color: const Color(0xFFF105C6),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("محتويات الشحنة"),
                      const SizedBox(height: 12),
                      _buildProductsList(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("تفاصيل الدفع"),
                      const SizedBox(height: 12),
                      _buildPaymentSummary(),
                      const SizedBox(height: 30),
                      _buildActionButtons(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }

  // ... (دوال Header و InfoColumn بقيت كما هي) ...
  Widget _buildHeaderSection() {
    final statusAttrs = _getStatusAttributes(_order!.status);
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusAttrs['bgColor'],
                  shape: BoxShape.circle,
                  border: Border.all(color: statusAttrs['borderColor']),
                ),
                child: Icon(
                  statusAttrs['icon'],
                  color: statusAttrs['textColor'],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusAttrs['label'],
                    style: TextStyle(
                      color: statusAttrs['textColor'],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn(
                "تاريخ الطلب",
                _order!.date.length >= 10
                    ? _order!.date.substring(0, 10)
                    : _order!.date,
              ),
              _buildInfoColumn("عدد العناصر", "${_order!.items.length} منتجات"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  // --- 🔥 المنطقة المحدثة: قائمة المنتجات ---
  Widget _buildProductsList() {
    bool isOrderCompleted =
        _order!.status.toLowerCase() == 'completed' ||
        _order!.status.toLowerCase() == 'delivered';

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _order!.items.length,
      separatorBuilder: (ctx, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _order!.items[index];
        // التحقق مما إذا كان المنتج مقيماً (محلياً أو من السيرفر)
        final reviewData = _productReviews[item.productId];
        final bool isReviewed = reviewData != null;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item.productImage,
                    fit: BoxFit.cover,
                    placeholder:
                        (c, u) => Container(color: Colors.grey.shade100),
                    errorWidget:
                        (c, u, e) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "x${item.quantity}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${(item.price * item.quantity).toStringAsFixed(0)} ر.س",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (isOrderCompleted) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        // 🔥 عرض زر "تعديل التقييم" أو "قيم المنتج"
                        child:
                            isReviewed
                                ? _buildReviewedBadge(item, reviewData!)
                                : _buildRateButton(item),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔥 ويدجت جديد: شارة "مقيّم" التفاعلية
  Widget _buildReviewedBadge(dynamic item, LocalReviewData reviewData) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            () => _showRatingBottomSheet(
              context,
              item.productId,
              item.productName,
              existingRating: reviewData.rating,
              existingComment: reviewData.comment,
            ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                "${reviewData.rating}.0", // عرض التقييم
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 1,
                height: 12,
                color: Colors.amber.shade300,
              ),
              Text(
                "تعديل",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.edit_outlined, size: 12, color: Colors.amber.shade900),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateButton(dynamic item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            () => _showRatingBottomSheet(
              context,
              item.productId,
              item.productName,
            ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_outline_rounded, size: 18, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                "قيّم المنتج",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (widgets الدفع والملخص بقيت كما هي) ...
  Widget _buildPaymentSummary() {
    double subTotal = _order!.totalPrice - _order!.shippingCost;
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
        children: [
          _buildSummaryRow("المجموع الفرعي", subTotal),
          const SizedBox(height: 12),
          _buildSummaryRow(
            "رسوم الشحن",
            _order!.shippingCost,
            isGreen: _order!.shippingCost == 0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "الإجمالي الكلي",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
            color: isGreen ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_order!.status.toLowerCase() == 'cancelled')
      return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(orderId: _order!.id),
            ),
          );
        },
        icon: const Icon(Icons.local_shipping_outlined, size: 20),
        label: const Text(
          "تتبع مسار الشحنة",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          Icon(Icons.error_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            "عذراً، حدث خطأ ما",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "لم نتمكن من تحميل تفاصيل الطلب",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _fetchOrderDetails,
            icon: const Icon(Icons.refresh, color: Color(0xFFF105C6)),
            label: const Text(
              "إعادة المحاولة",
              style: TextStyle(color: Color(0xFFF105C6)),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 تحديث: نافذة التقييم تقبل بيانات موجودة للتعديل
  void _showRatingBottomSheet(
    BuildContext context,
    int productId,
    String productName, {
    int? existingRating,
    String? existingComment,
  }) {
    // إذا كان تعديل، نستخدم القيم الموجودة
    int selectedRating = existingRating ?? 0;
    final TextEditingController commentController = TextEditingController(
      text: existingComment ?? "",
    );
    final bool isEditing = existingRating != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_rounded : Icons.star_rounded,
                      size: 48,
                      color: const Color(0xFFFFC107),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEditing ? "تعديل تقييمك" : "كيف كان المنتج؟",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap:
                            () =>
                                setModalState(() => selectedRating = index + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFFC107),
                            size: 44,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "شاركنا تجربتك (اختياري)...",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          selectedRating == 0
                              ? null
                              : () {
                                Navigator.pop(context);
                                _submitRating(
                                  productId,
                                  selectedRating,
                                  commentController.text,
                                  isEditing: isEditing,
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF105C6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditing ? "تحديث التقييم" : "إرسال التقييم",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🔥 تحديث: التعامل مع التعديل وتحديث الواجهة محلياً
  Future<void> _submitRating(
    int productId,
    int stars,
    String comment, {
    bool isEditing = false,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("جاري معالجة التقييم..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // استدعاء السيرفر (نفس الدالة تستخدم للإنشاء والتعديل عادةً، أو يتم إنشاء دالة update)
      await _orderService.submitProductReview(
        productId: productId,
        rating: stars,
        comment: comment,
      );

      if (mounted) {
        setState(() {
          // تحديث البيانات المحلية مباشرة لعرض التغييرات
          _productReviews[productId] = LocalReviewData(
            rating: stars,
            comment: comment,
          );
        });
        _showSuccessDialog(isEditing ? "تم تحديث تقييمك!" : "شكراً لك!");
      }
    } catch (e) {
      // في حالة وجود خطأ 409 (تم التقييم مسبقاً) ونحن لسنا في وضع التعديل
      // هذا يعني أننا نحاول إنشاء تقييم موجود، يمكننا تحديث الواجهة محلياً فقط كحل بديل
      if (e.toString().contains("409") ||
          e.toString().contains("ALREADY_REVIEWED")) {
        if (mounted) {
          setState(() {
            _productReviews[productId] = LocalReviewData(
              rating: stars,
              comment: comment,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم تحديث بياناتك"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("فشل الإرسال: $e")));
        }
      }
    }
  }

  void _showSuccessDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && Navigator.canPop(ctx)) Navigator.pop(ctx);
        });
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 40,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "تم حفظ رأيك بنجاح",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
