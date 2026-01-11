import 'package:flutter/material.dart';
import 'package:linyora_project/features/dashboards/merchant_dashboard_screen.dart';

class SubscriptionCancelledSuccessScreen extends StatelessWidget {
  const SubscriptionCancelledSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة معبرة
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 32),

            // العنوان
            const Text(
              "تم إلغاء التجديد التلقائي",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // التفاصيل
            Text(
              "لقد قمت بإلغاء التجديد التلقائي لاشتراكك بنجاح.\n\nيمكنك الاستمرار في الاستمتاع بمميزات الباقة الحالية حتى تاريخ انتهائها، ولن يتم خصم أي مبالغ منك مستقبلاً.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // زر العودة
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // العودة للصفحة الرئيسية (إزالة كل الصفحات السابقة والعودة للروت)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MerchantDashboardScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // أو اللون الرئيسي للتطبيق
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "العودة للرئيسية",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
