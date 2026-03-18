import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:linyora_project/features/orders/screens/tracking_screen.dart';

// ✅ 1. استيراد ملف الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

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

  final Map<int, LocalReviewData> _productReviews = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _order = widget.initialOrder;
      _populateInitialReviews();
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

  void _populateInitialReviews() {
    if (_order == null) return;

    for (var item in _order!.items) {
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

        _populateInitialReviews();
      }
    } catch (e) {
      if (mounted && !isBackground) setState(() => _isLoading = false);
      debugPrint("Error fetching details: $e");
    }
  }

  // ✅ تمرير الترجمة l10n واستخدام نصوص الحالات التي أضفناها سابقاً
  Map<String, dynamic> _getStatusAttributes(
    String status,
    AppLocalizations l10n,
  ) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'label': l10n.statusPending,
          'bgColor': Colors.amber.shade100,
          'textColor': Colors.amber.shade900,
          'borderColor': Colors.amber.shade200,
          'icon': Icons.access_time_rounded,
        };
      case 'processing':
        return {
          'label': l10n.statusProcessing,
          'bgColor': Colors.blue.shade100,
          'textColor': Colors.blue.shade900,
          'borderColor': Colors.blue.shade200,
          'icon': Icons.cached_rounded,
        };
      case 'shipped':
      case 'on_way':
      case 'out_for_delivery':
        return {
          'label': l10n.statusShipped,
          'bgColor': Colors.indigo.shade100,
          'textColor': Colors.indigo.shade900,
          'borderColor': Colors.indigo.shade200,
          'icon': Icons.local_shipping_rounded,
        };
      case 'completed':
      case 'delivered':
        return {
          'label': l10n.statusCompleted,
          'bgColor': Colors.green.shade100,
          'textColor': Colors.green.shade900,
          'borderColor': Colors.green.shade200,
          'icon': Icons.check_circle_outline_rounded,
        };
      case 'cancelled':
      case 'rejected':
      case 'returned':
        return {
          'label': l10n.statusCancelled,
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
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          l10n.orderDetailsTitle, // ✅ مترجم
          style: const TextStyle(
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
              ? _buildErrorState(l10n) // ✅ تمرير l10n
              : RefreshIndicator(
                onRefresh: _fetchOrderDetails,
                color: const Color(0xFFF105C6),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(l10n), // ✅ تمرير l10n
                      const SizedBox(height: 24),
                      _buildSectionTitle(l10n.shipmentContentsLabel), // ✅ مترجم
                      const SizedBox(height: 12),
                      _buildProductsList(l10n), // ✅ تمرير l10n
                      const SizedBox(height: 24),
                      _buildSectionTitle(l10n.paymentDetailsLabel), // ✅ مترجم
                      const SizedBox(height: 12),
                      _buildPaymentSummary(l10n), // ✅ تمرير l10n
                      const SizedBox(height: 30),
                      _buildActionButtons(l10n), // ✅ تمرير l10n
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

  Widget _buildHeaderSection(AppLocalizations l10n) {
    final statusAttrs = _getStatusAttributes(
      _order!.status,
      l10n,
    ); // ✅ تمرير l10n
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
                    "${l10n.orderNumberLabel}${_order!.orderNumber}", // ✅ مترجم
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
                l10n.orderDateLabel, // ✅ مترجم
                _order!.date.length >= 10
                    ? _order!.date.substring(0, 10)
                    : _order!.date,
              ),
              _buildInfoColumn(
                l10n.itemsCountLabel, // ✅ مترجم
                "${_order!.items.length} ${l10n.productsCountSuffix}", // ✅ مترجم
              ),
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

  Widget _buildProductsList(AppLocalizations l10n) {
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
                          "${(item.price * item.quantity).toStringAsFixed(0)} ${l10n.currencySAR}", // ✅ عملة مترجمة
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
                        child:
                            isReviewed
                                ? _buildReviewedBadge(
                                  item,
                                  reviewData!,
                                  l10n,
                                ) // ✅ تمرير l10n
                                : _buildRateButton(item, l10n), // ✅ تمرير l10n
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

  Widget _buildReviewedBadge(
    dynamic item,
    LocalReviewData reviewData,
    AppLocalizations l10n,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            () => _showRatingBottomSheet(
              context,
              item.productId,
              item.productName,
              l10n, // ✅ تمرير l10n
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
                "${reviewData.rating}.0",
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
                l10n.editBtn, // ✅ نص مترجم
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

  Widget _buildRateButton(dynamic item, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            () => _showRatingBottomSheet(
              context,
              item.productId,
              item.productName,
              l10n, // ✅ تمرير l10n
            ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_outline_rounded,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.rateProductBtn, // ✅ نص مترجم
                style: const TextStyle(
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

  Widget _buildPaymentSummary(AppLocalizations l10n) {
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
          _buildSummaryRow(
            l10n.subtotalLabel,
            subTotal,
            l10n,
          ), // ✅ مترجم (استخدمنا هذه الترجمة في شاشة السلة)
          const SizedBox(height: 12),
          _buildSummaryRow(
            l10n.shippingFeesLabel, // ✅ مترجم
            _order!.shippingCost,
            l10n,
            isGreen: _order!.shippingCost == 0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.grandTotalLabel, // ✅ مترجم (أضفناها في شاشة الدفع)
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                "${_order!.totalPrice.toStringAsFixed(2)} ${l10n.currencySAR}", // ✅ عملة مترجمة
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

  Widget _buildSummaryRow(
    String title,
    double amount,
    AppLocalizations l10n, {
    bool isGreen = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          amount == 0
              ? l10n.freeLabel
              : "${amount.toStringAsFixed(2)} ${l10n.currencySAR}", // ✅ مترجم
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isGreen ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
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
        label: Text(
          l10n.trackShipmentBtn, // ✅ مترجم
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            l10n.errorOopsLabel, // ✅ مترجم
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.failedToLoadOrderDetailsMsg, // ✅ مترجم
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _fetchOrderDetails,
            icon: const Icon(Icons.refresh, color: Color(0xFFF105C6)),
            label: Text(
              l10n.retryBtn, // ✅ مترجم (ترجمناها مسبقاً)
              style: const TextStyle(color: Color(0xFFF105C6)),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingBottomSheet(
    BuildContext context,
    int productId,
    String productName,
    AppLocalizations l10n, { // ✅ استقبال l10n
    int? existingRating,
    String? existingComment,
  }) {
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
                    isEditing
                        ? l10n.editYourRating
                        : l10n.howWasTheProduct, // ✅ مترجم
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
                      hintText: l10n.shareYourExperienceHint, // ✅ مترجم
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
                                  l10n, // ✅ تمرير l10n
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
                        isEditing
                            ? l10n.updateRatingBtn
                            : l10n.submitRatingBtn, // ✅ مترجم
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

  Future<void> _submitRating(
    int productId,
    int stars,
    String comment,
    AppLocalizations l10n, { // ✅ استقبال الترجمة
    bool isEditing = false,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.processingRatingMsg), // ✅ مترجم
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await _orderService.submitProductReview(
        productId: productId,
        rating: stars,
        comment: comment,
      );

      if (mounted) {
        setState(() {
          _productReviews[productId] = LocalReviewData(
            rating: stars,
            comment: comment,
          );
        });
        _showSuccessDialog(
          isEditing ? l10n.ratingUpdatedSuccess : l10n.thankYouMsg,
          l10n,
        ); // ✅ مترجم
      }
    } catch (e) {
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
            SnackBar(
              content: Text(l10n.dataUpdatedMsg), // ✅ مترجم
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${l10n.sendFailedMsg}$e")), // ✅ مترجم
          );
        }
      }
    }
  }

  void _showSuccessDialog(String title, AppLocalizations l10n) {
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
                Text(
                  l10n.opinionSavedSuccess, // ✅ مترجم
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
