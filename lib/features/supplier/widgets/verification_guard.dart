import 'package:flutter/material.dart';
import '../../../models/user_model.dart'; // تأكد من استيراد User Model

class SupplierVerificationGuard extends StatelessWidget {
  final UserModel currentUser;
  final Widget child; // الشاشة التي ستظهر إذا كان معتمداً

  const SupplierVerificationGuard({
    Key? key,
    required this.currentUser,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. إذا كان الحساب معتمداً، اعرض التطبيق فوراً
    if (currentUser.verificationStatus == 'approved') {
      return child;
    }

    // 2. إذا لم يكن معتمداً، اعرض شاشة القفل (تشبه تصميم React)
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("لوحة المورد"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // تصميم الكارت
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                ],
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الأيقونة والعنوان
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currentUser.verificationStatus == 'pending' ? Colors.amber.shade50 : Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      currentUser.verificationStatus == 'pending' ? Icons.access_time_filled : Icons.gpp_bad,
                      size: 40,
                      color: currentUser.verificationStatus == 'pending' ? Colors.amber.shade700 : Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    currentUser.verificationStatus == 'pending' 
                        ? "جاري مراجعة حسابك" 
                        : "التوثيق مطلوب",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  Text(
                    currentUser.verificationStatus == 'pending'
                        ? "شكراً لتسجيلك. يقوم فريقنا بمراجعة وثائقك حالياً. سنقوم بإعلامك فور تفعيل الحساب."
                        : "للبدء في بيع منتجاتك، يجب عليك إكمال عملية التوثيق ورفع المستندات المطلوبة.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (currentUser.verificationStatus != 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigator.pushNamed(context, '/supplier/verification');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("ابدأ التوثيق الآن", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
}