import 'package:flutter/material.dart';
import 'package:linyora_project/features/subscriptions/screens/subscription_cancelled_success_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ (تأكد من إضافتها في pubspec.yaml)
import '../../auth/providers/auth_provider.dart';
import '../services/subscription_service.dart';
import 'subscription_plans_screen.dart'; // للانتقال في حال أراد الترقية

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  final SubscriptionService _service = SubscriptionService();
  bool _isLoading = false;

  // دالة لتنسيق التاريخ
  String _formatDate(String? dateStr) {
    if (dateStr == null) return "غير محدد";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy', 'ar').format(date); // يحتاج intl
      // أو بدون intl: return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  // معالجة إلغاء الاشتراك
  Future<void> _handleCancelSubscription() async {
    // 1. عرض نافذة التأكيد (كما هي في كودك)
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("إلغاء الاشتراك؟"),
            content: const Text(
              "هل أنت متأكد أنك تريد إلغاء اشتراكك؟ ستفقد الوصول للميزات المدفوعة بنهاية الفترة الحالية.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("تراجع"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("نعم، إلغاء"),
              ),
            ],
          ),
    );

    // إذا لم يوافق، نخرج
    if (confirm != true) return;

    // بدء التحميل
    setState(() => _isLoading = true);

    try {
      // 2. استدعاء API الإلغاء
      await _service.cancelSubscription();

      if (mounted) {
        // 3. تحديث بيانات المستخدم في الخلفية
        // هذا مهم لكي تظهر حالة الاشتراك كـ "ملغى" أو "غير متجدد" عند العودة
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();

        // 4. ✅ التوجيه لصفحة النجاح بدلاً من عرض SnackBar
        // نستخدم pushReplacement لإغلاق صفحة "اشتراكي" واستبدالها بصفحة النجاح
        // حتى لا يعود المستخدم لصفحة الاشتراك بزر الرجوع
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SubscriptionCancelledSuccessScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await Provider.of<AuthProvider>(context, listen: false).refreshUser();
  }

  Widget _buildNoSubscriptionView() {
    return Center(
      child: SingleChildScrollView(
        // AlwaysScrollableScrollPhysics ضرورية لكي يعمل السحب للتحديث حتى لو كانت الصفحة فارغة
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة توضيحية جذابة
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_membership_rounded,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 30),

            // نصوص توضيحية
            const Text(
              "لا يوجد اشتراك نشط",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "اشتركي الآن في إحدى باقات لينيورا للحصول على صلاحيات الدروب شيبينج ومميزات حصرية لتنمية أعمالك.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // زر التوجه لصفحة الخطط
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPlansScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E), // Primary Color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "استعراض خطط الاشتراك",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // نص مساعد للسحب للتحديث
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_downward,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 5),
                Text(
                  "اسحبي للأسفل للتحديث إذا كنتِ قد اشتركتِ للتو",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // جلب بيانات الاشتراك من المستخدم الحالي
    final user = Provider.of<AuthProvider>(context).user;
    final sub = user?.subscription;

    // إذا لم يكن هناك بيانات (نظرياً لا يجب أن يحدث إذا دخلنا هنا)
    if (sub == null)
      return const Scaffold(body: Center(child: Text("لا يوجد اشتراك نشط")));

    // استخراج البيانات من الـ JSON الذي ظهر في اللوج
    // ملاحظة: sub.planName قد يكون null إذا لم نحدث المودل ليقرأ الـ nested object
    // لذا سنقرأه بحذر أو نفترض أنك حدثت المودل
    final String planName = sub.planName ?? "باقة غير معروفة";
    // إذا كنت لم تحدث SubscriptionState ليقرأ السعر، يمكنك عرضه كنص ثابت أو تعديل المودل
    // سنفترض هنا تصميماً جميلاً

    final bool isActive = sub.status == 'active';
    final String endDate = _formatDate(
      user?.subscription?.endDate,
    ); // نفترض أنك أضفت endDate للمودل

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.purple,
        child:
            sub == null
                ? _buildNoSubscriptionView() // ويدجت يعرض رسالة لا يوجد اشتراك
                : SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // ضروري لعمل الـ Refresh
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 1. بطاقة الحالة (Active Badge)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isActive
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? Icons.check_circle : Icons.error,
                              color: isActive ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive ? "اشتراك نشط" : "اشتراك غير نشط",
                              style: TextStyle(
                                color:
                                    isActive
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. بطاقة تفاصيل الباقة (VIP Card Design)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF43F5E),
                              Color(0xFF9333EA),
                            ], // Rose to Purple
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF43F5E).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Icon(
                                Icons.star,
                                size: 150,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "الباقة الحالية",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    planName.toUpperCase(), // اسم الباقة
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "تاريخ البدء",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(
                                              user?.subscription?.startDate,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            "تاريخ التجديد",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            endDate,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. الصلاحيات (Permissions)
                      if (sub.hasDropshippingAccess)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.purple.withOpacity(0.2),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_download, color: Colors.purple),
                              SizedBox(width: 12),
                              Text(
                                "صلاحية الدروب شيبينج مفعلة ✅",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                      // 4. أزرار التحكم
                      const SizedBox(height: 20),
                      if (isActive) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // توجيه لصفحة الخطط للترقية
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const SubscriptionPlansScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.upgrade),
                            label: const Text("ترقية الباقة"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 1,
                              side: const BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: TextButton.icon(
                            onPressed:
                                _isLoading ? null : _handleCancelSubscription,
                            icon:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.red,
                                    ),
                            label: Text(
                              _isLoading
                                  ? "جاري المعالجة..."
                                  : "إلغاء تجديد الاشتراك",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      ),
    );
  }
}
