import 'dart:io';

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
        data: {'email': email, 'password': password},
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

  // --- تسجيل مستخدم جديد ---
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required int roleId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'phoneNumber':
              phone, // تأكد: هل الباك إند يتوقع phone أو phoneNumber؟
          'password': password,
          'role_id': roleId, // تأكد: هل الباك إند يتوقع roleId أو role_id؟
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      String errorMessage = 'فشل إنشاء الحساب';

      if (e.response != null) {
        // طباعة الخطأ في الكونسول للمطور
        print("🚨 Server Error Data: ${e.response?.data}");

        final data = e.response?.data;

        if (data is Map<String, dynamic>) {
          // جلب الرسالة إذا كانت موجودة، أو تجميع الأخطاء إذا كانت داخل حقل errors
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('errors')) {
            // معالجة الأخطاء القادمة من Laravel مثلاً
            final errors = data['errors'];
            if (errors is Map) {
              errorMessage = errors.values.join('\n');
            } else {
              errorMessage = errors.toString();
            }
          } else {
            errorMessage = data.toString();
          }
        } else if (data is String) {
          errorMessage = data;
        }
      }

      // رمي نص الخطأ فقط
      throw errorMessage;
    } catch (e) {
      print("🚨 Unknown Error: $e");
      throw 'حدث خطأ غير متوقع: $e';
    }
  }

  // --- استعادة كلمة المرور ---
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/forgot-password', // تأكد من المسار
        data: {'email': email},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'حدث خطأ، تأكد من البريد';
    }
  }

  // --- إعادة تعيين كلمة المرور (بعد الضغط على الرابط) ---
  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final response = await _apiClient.post(
        '/auth/reset-password/$token', // يتم تمرير التوكن في الرابط
        data: {'password': newPassword},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'فشل إعادة تعيين كلمة المرور';
    }
  }

  // في ملف AuthService.dart

  // --- إعادة إرسال كود التحقق ---
  // في ملف AuthService.dart

  Future<bool> resendVerificationCode(String email) async {
    // 1. تأكد من أن هذا المسار يطابق الموجود في الباك إند تماماً
    const String endpoint = '/auth/resend-verification';

    print(
      "📡 Attempting to POST to: ${_apiClient}$endpoint",
    ); // طباعة الرابط للمراقبة

    try {
      final response = await _apiClient.post(endpoint, data: {'email': email});

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("❌ Error 404: الرابط غير موجود. تأكد من صحة المسار: $endpoint");
      print("تفاصيل الخطأ: ${e.response?.data}");

      if (e.response?.statusCode == 404) {
        throw 'خطأ في الاتصال: رابط الخدمة غير موجود (404)';
      }
      throw e.response?.data['message'] ?? 'فشل إعادة إرسال الكود';
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    File? imageFile,
  }) async {
    print("🚀 Start updateProfile...");

    // ===> محاولة استعادة المستخدم إذا كان null <===
    if (_currentUser == null || _currentUser!.token == null) {
      print("⚠️ User is null in RAM, trying to reload from Storage...");
      final savedToken = await _storage.read(key: 'auth_token');

      if (savedToken != null) {
        try {
          final response = await _apiClient.get(
            '/users/profile',
            options: Options(headers: {'Authorization': 'Bearer $savedToken'}),
          );

          if (response.statusCode == 200) {
            final data =
                response.data['user'] ?? response.data['data'] ?? response.data;
            _currentUser = UserModel.fromJson(data);
            _currentUser = _currentUser!.copyWith(token: savedToken);
            print("✅ User restored successfully: ${_currentUser!.name}");
          }
        } catch (e) {
          print("❌ Failed to restore user: $e");
        }
      }
    }

    if (_currentUser == null || _currentUser!.token == null) {
      print("❌ Error: User or Token is null");
      return false;
    }

    final String token = _currentUser!.token!;
    bool isTextUpdated = false;

    // ---------------------------------------------------------
    // الخطوة 1: تحديث النصوص
    // ---------------------------------------------------------
    try {
      print("📡 Sending PUT Request to /users/profile...");
      final bodyData = {
        "name": name,
        "email": _currentUser!.email,
        "phone": phone,
      };

      final response = await _apiClient.put(
        '/users/profile',
        data: bodyData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        print("✅ Text Update Success");
        final responseData = response.data;
        final updatedUserData = responseData['user'] ?? responseData;

        _currentUser = _currentUser!.copyWith(
          name: updatedUserData['name'],
          phone: updatedUserData['phone'] ?? updatedUserData['phone_number'],
        );
        isTextUpdated = true;
      } else {
        print("⚠️ Server Refused Text Update: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Text Update Error: $e");
      return false;
    }

    // ---------------------------------------------------------
    // الخطوة 2: تحديث الصورة (مع زيادة الوقت)
    // ---------------------------------------------------------
    if (imageFile != null) {
      print("📸 Image found, starting upload...");
      try {
        String fileName = imageFile.path.split('/').last;

        // تأكد أن الاسم هنا يطابق الباك إند (profilePicture)
        FormData formData = FormData.fromMap({
          "profilePicture": await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          ),
        });

        final response = await _apiClient.post(
          '/users/profile/picture',
          data: formData,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            // 👇👇👇 الإضافة الهامة جداً لحل مشكلة الـ Timeout 👇👇👇
            sendTimeout: const Duration(minutes: 2), // انتظار دقيقتين للإرسال
            receiveTimeout: const Duration(
              minutes: 2,
            ), // انتظار دقيقتين للاستقبال
          ),
        );

        if (response.statusCode == 200) {
          print("✅ Image Upload Success");
          final responseData = response.data;
          _currentUser = _currentUser!.copyWith(
            avatar: responseData['profile_picture_url'],
          );
        } else {
          print("⚠️ Image Upload Failed: ${response.statusCode}");
        }
      } catch (e) {
        print("❌ Image Update Error: $e");
        // لا نوقف الدالة هنا لأن تحديث الاسم نجح
      }
    }

    if (isTextUpdated) {
      return true;
    }

    return false;
  }

  // --- الخطوة 2: التحقق من الكود واستلام التوكن ---
  Future<UserModel?> verifyLogin(String email, String code) async {
    try {
      final response = await _apiClient.post(
        "/auth/verify-login", // تأكد من وجود هذا المسار في الباك إند
        data: {'email': email, 'code': code},
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
      // إضافة الهيدر يدوياً للتأكد
      final response = await _apiClient.get(
        '/users/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data =
            response.data['user'] ?? response.data['data'] ?? response.data;
        // دمج التوكن مع البيانات لأنه قد لا يأتي من بروفايل المستخدم
        _currentUser = UserModel.fromJson(data).copyWith(token: token);
        debugPrint("✅ User Auto-Logged in: ${_currentUser?.name}");
      } else {
        debugPrint("⚠️ Token expired or invalid: ${response.statusCode}");
        await logout();
      }
    } catch (e) {
      debugPrint("❌ Auto login failed: $e");
      // في حالة 401 أو Timeout، نخرج المستخدم لكي يسجل دخول من جديد
      await logout();
    }
  }

  // --- تسجيل الخروج ---
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _currentUser = null;
  }
}
