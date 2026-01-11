import 'package:flutter/material.dart';
import '../../../../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../../core/api/api_client.dart'; // ✅ تأكد من استيراد ApiClient

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final ApiClient _apiClient = ApiClient(); // ✅ نستخدمه للطلبات المخصصة

  // متغير محلي لتخزين المستخدم بعد دمج الاشتراك
  UserModel? _user;

  // إذا كانت البيانات المدمجة موجودة نعرضها، وإلا نأخذ البيانات الخام من السيرفس
  UserModel? get user => _user ?? _authService.currentUser;

  bool get isLoggedIn => _authService.isLoggedIn;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// تهيئة التطبيق
  Future<void> initAuth() async {
    _setLoading(true);
    await _authService.tryAutoLogin();

    // ✅ إذا نجح الدخول التلقائي، نقوم بجلب بيانات الاشتراك ودمجها فوراً
    if (_authService.isLoggedIn) {
      await refreshUser();
    }
    _setLoading(false);
  }

  /// ✅ الدالة السحرية: تجلب البروفايل + الاشتراك وتدمجهما
  Future<void> refreshUser() async {
    try {
      // 1. تجهيز الطلبين (User Profile + Subscription Status)
      // نستخدم Future.wait لتشغيلهما في نفس الوقت لسرعة الأداء (مثل Promise.all في React)

      final userFuture = _apiClient.get('/users/profile');

      // نستخدم catchError للاشتراك لكي لا يفشل الكود كله إذا لم يكن هناك اشتراك
      final subscriptionFuture = _apiClient
          .get('/subscriptions/status')
          .catchError((e) {
            print("⚠️ Failed to fetch subscription (might be 404): $e");
            return null;
          });

      // 2. انتظار النتائج
      final responses = await Future.wait([userFuture, subscriptionFuture]);

      final userResponse = responses[0];
      final subscriptionResponse = responses[1];

      if (userResponse.statusCode == 200) {
        // نأخذ بيانات المستخدم كـ Map قابلة للتعديل
        Map<String, dynamic> userData = userResponse.data;

        // 3. ✅ دمج بيانات الاشتراك يدوياً
        if (subscriptionResponse != null &&
            subscriptionResponse.statusCode == 200) {
          print("✅ Subscription Data Fetched: ${subscriptionResponse.data}");
          // نضع استجابة الاشتراك داخل حقل 'subscription' في بيانات المستخدم
          userData['subscription'] = subscriptionResponse.data;
        } else {
          print("ℹ️ No active subscription data found.");
        }

        // 4. تحديث المودل بالبيانات الكاملة
        _user = UserModel.fromJson(userData);

        // (اختياري) تحديث السيرفس إذا كان يدعم ذلك
        // _authService.updateUser(_user!);

        print("User Role: ${_user?.role}");
        print("Subscription Status: ${_user?.subscription?.status}");
      }
    } catch (e) {
      print("❌ Error refreshing user data: $e");
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null; // تصفير البيانات المحلية
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
