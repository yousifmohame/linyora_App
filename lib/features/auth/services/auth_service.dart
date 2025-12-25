import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/user_model.dart';

class AuthService {
  // 1. Singleton Pattern: لضمان وجود نسخة واحدة طوال حياة التطبيق
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 2. متغير لحفظ المستخدم الحالي في الذاكرة (RAM)
  UserModel? _currentUser;

  // Getter للوصول للمستخدم من الـ Drawer وغيره
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // --- الخطوة 1: تسجيل الدخول (طلب الكود) ---
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login, 
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      } else if (e.response?.statusCode == 403) {
        throw 'الحساب غير مفعل، يرجى تفعيل الحساب أولاً';
      } else if (e.response?.statusCode == 429) {
        throw 'حاولت الدخول مرات عديدة، يرجى الانتظار قليلاً';
      }
      throw e.response?.data['message'] ?? 'حدث خطأ في الاتصال';
    } catch (e) {
      throw 'حدث خطأ غير متوقع: $e';
    }
  }

  // --- الخطوة 2: التحقق من الكود واستلام التوكن ---
  Future<UserModel?> verifyLogin(String email, String code) async {
    try {
      final response = await _apiClient.post(
        "/auth/verify-login", // تأكد من وجود هذا المسار في الباك إند
        data: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // 1. حفظ التوكن بأمان
        final String token = data['token'];
        await _storage.write(key: 'auth_token', value: token);

        // 2. تحديث المتغير في الذاكرة لكي يراه الـ Drawer فوراً
        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        }
        
        return _currentUser;
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'الكود غير صحيح أو انتهت صلاحيته';
    }
  }

  // --- دالة مهمة: جلب بيانات المستخدم عند فتح التطبيق (Auto Login) ---
  // يتم استدعاؤها في main.dart أو Splash Screen
  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;

    try {
      // نفترض وجود مسار لجلب البروفايل (Profile)
      final response = await _apiClient.get('/users/profile'); // أو /auth/me
      
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        _currentUser = UserModel.fromJson(data);
        debugPrint("User Auto-Logged in: ${_currentUser?.name}");
      } else {
        // التوكن منتهي الصلاحية
        await logout();
      }
    } catch (e) {
      debugPrint("Auto login failed: $e");
      await logout();
    }
  }

  // --- تسجيل الخروج ---
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _currentUser = null;
  }
}