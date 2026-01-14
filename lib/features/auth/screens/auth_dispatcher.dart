import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

// استيراد الشاشات (تأكد من صحة المسارات في مشروعك)
import '../../layout/main_layout_screen.dart'; // العميل
import '../../dashboards/merchant_dashboard_screen.dart'; // التاجر
import '../../dashboards/model_dashboard.dart'; // المودل
import '../../dashboards/supplier_dashboard.dart'; // المورد

class AuthDispatcher extends StatelessWidget {
  final UserModel user;

  const AuthDispatcher({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // التوجيه بناءً على الـ Getter (role) الذي أنشأناه في المودل
    switch (user.role) {
      case UserRole.admin:
        return const Scaffold(body: Center(child: Text("لوحة تحكم الإدارة")));

      case UserRole.merchant:
        return const MerchantDashboardScreen();

      case UserRole.model:
        return const ModelDashboard();

      case UserRole.supplier:
        return const SupplierDashboardScreen();

      case UserRole.customer:
      default:
        // العميل العادي يذهب للتطبيق الرئيسي
        return const MainLayoutScreen();
    }
  }
}
