import 'package:flutter/material.dart';
import 'package:linyora_project/features/dashboards/merchant_dashboard_screen.dart';

// ✅ استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

class SubscriptionCancelledSuccessScreen extends StatelessWidget {
  const SubscriptionCancelledSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

            Text(
              l10n.autoRenewalCancelledTitle, // ✅ مترجم
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Text(
              l10n.autoRenewalCancelledDesc, // ✅ مترجم
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MerchantDashboardScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.backToHomeBtn, // ✅ مترجم
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
