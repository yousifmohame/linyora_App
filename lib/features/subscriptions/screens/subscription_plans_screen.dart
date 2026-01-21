import 'package:flutter/material.dart';
import 'package:linyora_project/features/subscriptions/screens/payment_webview_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ لفتح رابط الدفع
import '../../auth/providers/auth_provider.dart';
import '../services/subscription_service.dart';
import '../../../models/subscription_plan_model.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final SubscriptionService _service = SubscriptionService();
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  int? _selectedPlanId; // لتحديد البطاقة التي يتم معالجتها حالياً

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  // جلب الخطط
  Future<void> _fetchPlans() async {
    try {
      final plans = await _service.getPlans();
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

  // التعامل مع الاشتراك (فتح رابط الدفع)
  Future<void> _handleSubscribe(int planId) async {
    setState(() => _selectedPlanId = planId);

    try {
      // 1. جلب رابط الدفع من السيرفر
      final String? checkoutUrl = await _service.createCheckoutSession(planId);

      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        if (!mounted) return;

        // ✅ 2. فتح صفحة الدفع الداخلية وانتظار النتيجة
        final bool? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PaymentWebViewScreen(checkoutUrl: checkoutUrl),
          ),
        );

        // ✅ 3. معالجة النتيجة بعد عودة المستخدم من صفحة الدفع
        if (result == true) {
          // الدفع ناجح! نحدث البيانات ونغلق الصفحة
          setState(() => _isLoading = true);
          await Provider.of<AuthProvider>(context, listen: false).refreshUser();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم الاشتراك بنجاح!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // الدفع فشل أو تم إلغاؤه
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إلغاء عملية الدفع'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        throw Exception('لم يتم استلام رابط الدفع');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _selectedPlanId = null);
    }
  }

  // زر للتحقق من الاشتراك (يضغط عليه المستخدم بعد العودة من المتصفح)
  Future<void> _checkSubscriptionStatus() async {
    setState(() => _isLoading = true);
    await Provider.of<AuthProvider>(context, listen: false).refreshUser();
    if (mounted) {
      // إذا أصبح مشتركاً، نغلق الصفحة
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null && user.isSubscribed) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم تفعيل الاشتراك بعد، يرجى المحاولة لاحقاً'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text(
            "اختاري باقتكِ",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            // زر لتحديث الحالة يدوياً بعد الدفع
            TextButton(
              onPressed: _checkSubscriptionStatus,
              child: const Text("تحقق من الدفع"),
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF43F5E)),
                )
                : _plans.isEmpty
                ? const Center(child: Text("لا توجد باقات متاحة حالياً"))
                : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _plans.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    return _buildPlanCard(_plans[index]);
                  },
                ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final bool isProcessing = _selectedPlanId == plan.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${plan.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF43F5E),
                      ),
                    ),
                    const Text(
                      "ريال / شهرياً",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),

            // Features List
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Subscribe Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    (_selectedPlanId != null)
                        ? null
                        : () => _handleSubscribe(plan.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E), // Rose-500
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child:
                    isProcessing
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          "اشتركي الآن",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
