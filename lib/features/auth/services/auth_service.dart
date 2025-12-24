import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- الخطوة 1: إرسال البيانات وطلب الكود ---
  // تعيد true إذا تم إرسال الكود بنجاح
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login, // /auth/login
        data: {
          'email': email,
          'password': password,
        },
      );

      // الباك إند يعيد 200 ورسالة "Verification code sent..."
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
      throw 'حدث خطأ غير متوقع';
    }
  }

  // --- الخطوة 2: التحقق من الكود واستلام التوكن ---
  Future<UserModel?> verifyLogin(String email, String code) async {
    try {
      // تأكد من إضافة المسار في ApiConstants: static const String verifyLogin = "/auth/verify-login";
      final response = await _apiClient.post(
        "/auth/verify-login", 
        data: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // هنا نستلم التوكن فعلياً
        final String token = data['token'];
        await _storage.write(key: 'auth_token', value: token);

        if (data['user'] != null) {
          return UserModel.fromJson(data['user']);
        }
      }
      return null;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'الكود غير صحيح أو انتهت صلاحيته';
    }
  }

  logout() {}
}