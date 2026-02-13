import 'package:flutter/material.dart';
import 'package:linyora_project/features/subscriptions/services/subscription_service.dart';
import './payment_services.dart' hide PaymentService;
import 'package:provider/provider.dart';
import 'package:linyora_project/features/auth/providers/auth_provider.dart';
import 'package:linyora_project/models/subscription_plan_model.dart';
import 'package:linyora_project/features/subscriptions/screens/payment_Services.dart'; // تأكد من المسار

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final SubscriptionService _dataService =
      SubscriptionService(); // لجلب الباقات
  final PaymentService _paymentService = PaymentService(); // ✅ للدفع

  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  int? _selectedPlanId; // لتحديد الزر الذي يتم تحميله

  // الألوان
  final Color _activeColor = const Color(0xFF10B981);
  final Color _primaryColor = const Color(0xFFF43F5E);
  final Color _darkText = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final plans = await _dataService.getPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ دالة الاشتراك الجديدة
  // داخل الكلاس _SubscriptionPlansScreenState

  Future<void> _handleSubscribe(int planId) async {
    setState(() => _selectedPlanId = planId);

    // ✅ لم نعد بحاجة لجلب التوكن هنا
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // استدعاء الخدمة مباشرة (أنظف وأسهل)
    await _paymentService.subscribeToPlan(
      context: context,
      planId: planId,
      paymentMethodId: null,
      onSuccess: () async {
        // تحديث البيانات بعد النجاح
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم تفعيل الاشتراك بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      },
    );

    if (mounted) {
      setState(() => _selectedPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // قراءة بيانات المستخدم لمعرفة الباقة الحالية
    final user = Provider.of<AuthProvider>(context).user;
    final subscription = user?.subscription;

    int? currentPlanId;
    if (subscription != null && subscription.status == 'active') {
      currentPlanId = subscription.planId;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "خطط الاشتراك",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: _primaryColor))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "اكتشفي الباقة المثالية لكِ",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "استمتعي بميزات حصرية وأدوات متقدمة لتنمية أعمالك",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _plans.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final plan = _plans[index];
                        final bool isMyPlan =
                            (currentPlanId != null && plan.id == currentPlanId);
                        return _buildProfessionalCard(plan, isMyPlan);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfessionalCard(SubscriptionPlan plan, bool isMyPlan) {
    // هل يتم معالجة هذا الزر حالياً؟
    final bool isProcessing = _selectedPlanId == plan.id;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isMyPlan ? Border.all(color: _activeColor, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // الهيدر
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      isMyPlan
                          ? _activeColor.withOpacity(0.05)
                          : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _darkText,
                          ),
                        ),
                        if (isMyPlan)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "✅ باقتك الحالية",
                              style: TextStyle(
                                fontSize: 12,
                                color: _activeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              plan.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${plan.price.toInt()}",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: _darkText,
                            ),
                          ),
                          TextSpan(
                            text: " ر.س",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _darkText,
                            ),
                          ),
                          TextSpan(
                            text: "\n/ شهرياً",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // الميزات والزر
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ...plan.features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: isMyPlan ? _activeColor : _primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            (isMyPlan || _selectedPlanId != null)
                                ? null
                                : () => _handleSubscribe(plan.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isMyPlan ? Colors.grey[200] : _primaryColor,
                          foregroundColor:
                              isMyPlan ? Colors.grey : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                              isMyPlan
                                  ? Colors.green.shade50
                                  : Colors.grey[300],
                          disabledForegroundColor:
                              isMyPlan ? Colors.green : Colors.grey[600],
                        ),
                        child:
                            isProcessing
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  isMyPlan ? "مشترك حالياً ✅" : "اشتراك الآن",
                                  style: const TextStyle(
                                    fontSize: 16,
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
        if (!isMyPlan && plan.price > 0 && plan.price < 500)
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "الأكثر طلباً 🔥",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
