import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../layout/main_layout_screen.dart'; // للعملاء (Home)
import '../../dashboards/merchant_dashboard.dart';
import '../../dashboards/model_dashboard.dart';
import '../../dashboards/supplier_dashboard.dart';

class AuthDispatcher extends StatelessWidget {
  final UserModel user;

  const AuthDispatcher({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.merchant:
        return const MerchantDashboard();
      case UserRole.model:
        return const ModelDashboard();
      case UserRole.supplier:
        return const SupplierDashboard();
      case UserRole.admin:
        return const Scaffold(body: Center(child: Text("لوحة الأدمن (قريباً)")));
      case UserRole.customer:
      default:
        // العميل العادي يذهب للتطبيق الرئيسي (تسوق + ريلز)
        return const MainLayoutScreen();
    }
  }
}