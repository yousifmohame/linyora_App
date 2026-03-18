import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linyora_project/models/order_model.dart';
import 'package:linyora_project/features/orders/services/order_service.dart';

// ✅ 1. استيراد ملف الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({Key? key, required this.orderId})
    : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late AnimationController _controller;
  late Animation<double> _animation;

  OrderModel? _order;
  bool _isLoading = true;
  int _currentStepIndex = 0;

  // أبعاد التصميم
  final double _stepHeight = 100.0;
  final double _topPadding = 40.0;
  final Color kPrimaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    // إعداد الأنيميشن
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // قيمة مبدئية للأنيميشن
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);

    _fetchOrderData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderData() async {
    try {
      final order = await _orderService.getOrderDetails(widget.orderId);
      if (mounted && order != null) {
        setState(() {
          _order = order;
          _isLoading = false;
          _currentStepIndex = _getStepIndex(order.status);
        });

        // تحديث الأنيميشن للذهاب للمرحلة الحالية
        _animation = Tween<double>(
          begin: 0.0,
          end: _currentStepIndex.toDouble(),
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );

        _controller.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching tracking: $e");
    }
  }

  // دالة ذكية لتحويل حالة النص إلى رقم مرحلة
  int _getStepIndex(String status) {
    String s = status.toLowerCase();
    if (['pending', 'confirmed', 'hold'].contains(s)) return 0;
    if (['processing', 'packing', 'ready'].contains(s)) return 1;
    if (['shipped', 'on_way', 'out_for_delivery'].contains(s)) return 2;
    if (['delivered', 'completed'].contains(s)) return 3;
    return 0; // الافتراضي
  }

  // ✅ ترجمة حالة الطلب المعروضة في الأعلى (استخدمنا نفس ترجمات الشاشة السابقة)
  String _getTranslatedStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.statusPending; // "قيد الانتظار"
      case 'processing':
        return l10n.statusProcessing; // "قيد التنفيذ"
      case 'shipped':
      case 'on_way':
      case 'out_for_delivery':
        return l10n.statusShipped; // "تم الشحن"
      case 'completed':
      case 'delivered':
        return l10n.statusCompleted; // "مكتمل"
      case 'cancelled':
        return l10n.statusCancelled; // "ملغي"
      default:
        return status;
    }
  }

  // ✅ تمرير l10n لترجمة المراحل
  List<Map<String, String>> _getSteps(AppLocalizations l10n) {
    String dateStr =
        _order != null
            ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(_order!.date))
            : '--';

    return [
      {
        'title': l10n.step1Title, // ✅ مترجم
        'subtitle': l10n.step1Subtitle, // ✅ مترجم
        'date': dateStr,
      },
      {
        'title': l10n.step2Title, // ✅ مترجم
        'subtitle': l10n.step2Subtitle, // ✅ مترجم
        'date':
            _currentStepIndex >= 1
                ? l10n.completedLabel
                : l10n.soonLabel, // ✅ مترجم
      },
      {
        'title': l10n.step3Title, // ✅ مترجم
        'subtitle': l10n.step3Subtitle, // ✅ مترجم
        'date':
            _currentStepIndex >= 2
                ? l10n.completedLabel
                : l10n.soonLabel, // ✅ مترجم
      },
      {
        'title': l10n.step4Title, // ✅ مترجم
        'subtitle': l10n.step4Subtitle, // ✅ مترجم
        'date':
            _currentStepIndex >= 3
                ? l10n.completedLabel
                : l10n.soonLabel, // ✅ مترجم
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_order == null) {
      return Scaffold(
        body: Center(child: Text(l10n.failedToLoadData)),
      ); // ✅ مترجم
    }

    // حالة خاصة إذا كان الطلب ملغياً
    if (_order!.status.toLowerCase() == 'cancelled') {
      return _buildCancelledScreen(l10n); // ✅ تمرير l10n
    }

    final steps = _getSteps(l10n); // ✅ تمرير l10n

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n.trackingTitle, // ✅ مترجم
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. معلومات الهيدر
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPrimaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      size: 40,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${l10n.shipmentNumberLabel}${_order!.orderNumber}", // ✅ مترجم
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${l10n.currentStatusLabel}${_getTranslatedStatus(_order!.status, l10n)}", // ✅ مترجم
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. منطقة التتبع (Timeline)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العمود الأيسر: الخط والشاحنة
                  _buildAnimatedLine(steps.length),

                  const SizedBox(width: 16),

                  // العمود الأيمن: النصوص
                  Expanded(
                    child: Column(
                      children: List.generate(steps.length, (index) {
                        return SizedBox(
                          height: _stepHeight,
                          child: _buildStepText(
                            index,
                            steps[index],
                            l10n,
                          ), // ✅ تمرير l10n
                        );
                      }),
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

  // شاشة خاصة للطلب الملغي
  Widget _buildCancelledScreen(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderStatusTitle)), // ✅ مترجم
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, size: 80, color: Colors.red[300]),
            const SizedBox(height: 20),
            Text(
              l10n.orderCancelledMsg, // ✅ مترجم
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("${l10n.orderNumberLabel}${_order?.orderNumber}"), // ✅ مترجم
          ],
        ),
      ),
    );
  }

  // ويدجت رسم الخط والشاحنة
  Widget _buildAnimatedLine(int totalSteps) {
    return SizedBox(
      width: 40,
      height: (totalSteps - 1) * _stepHeight + 50,
      child: Stack(
        children: [
          Positioned(
            top: _topPadding,
            left: 19,
            bottom: 0,
            child: Container(width: 2, color: Colors.grey.shade300),
          ),
          Positioned(
            top: _topPadding,
            left: 19,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 2,
                  height: _animation.value * _stepHeight,
                  color: kPrimaryBlue,
                );
              },
            ),
          ),
          ...List.generate(totalSteps, (index) {
            return Positioned(
              top: _topPadding + (index * _stepHeight) - 6,
              left: 13,
              child: _buildDot(index),
            );
          }),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: _topPadding + (_animation.value * _stepHeight) - 20,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: kPrimaryBlue,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        bool isCompleted = _animation.value >= index;

        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isCompleted ? kPrimaryBlue : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow:
                isCompleted
                    ? [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ]
                    : [],
          ),
        );
      },
    );
  }

  Widget _buildStepText(
    int index,
    Map<String, String> stepInfo,
    AppLocalizations l10n,
  ) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        bool isActive = _animation.value >= index;
        bool isCurrent = (_animation.value.round() == index);

        return Opacity(
          opacity: isActive ? 1.0 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stepInfo['title']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  Text(
                    stepInfo['date']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? kPrimaryBlue : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stepInfo['subtitle']!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),

              if (isCurrent && _currentStepIndex != 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.inProgressLabel, // ✅ مترجم
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
