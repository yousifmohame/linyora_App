import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // استيراد ملفات اللغة

class MerchantDashboard extends StatelessWidget {
  const MerchantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('data'), // نص مترجم
        backgroundColor: Colors.blue[900], // لون مميز للتاجر
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text("إحصائيات مبيعاتك تظهر هنا"),
            ElevatedButton(
              onPressed: () {}, 
              child: const Text("إضافة منتج جديد")
            ),
          ],
        ),
      ),
    );
  }
}