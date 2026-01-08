import 'package:flutter/material.dart';
import '../../../../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  // نستخدم النسخة الـ Singleton التي أنشأتها في AuthService
  final AuthService _authService = AuthService.instance;

  // جلب المستخدم الحالي مباشرة من السيرفس
  UserModel? get user => _authService.currentUser;
  
  // معرفة هل المستخدم مسجل دخول أم لا
  bool get isLoggedIn => _authService.isLoggedIn;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// دالة لتهيئة التطبيق عند الفتح (تجريب تسجيل الدخول التلقائي)
  Future<void> initAuth() async {
    _setLoading(true);
    await _authService.tryAutoLogin();
    _setLoading(false);
  }

  /// تحديث بيانات المستخدم (نستخدمها بعد قبول الاتفاقية مثلاً)
  Future<void> refreshUser() async {
    // نقوم بإعادة طلب البروفايل لتحديث البيانات في الذاكرة
    await _authService.tryAutoLogin(); 
    notifyListeners();
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}