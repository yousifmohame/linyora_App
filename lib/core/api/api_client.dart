import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )),
        _storage = const FlutterSecureStorage() {
    
    // إضافة Interceptor لإرفاق التوكن تلقائياً
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // نقرأ التوكن من التخزين الآمن
        final token = await _storage.read(key: 'auth_token');
        
        if (token != null) {
          // نضيف التوكن في الهيدر: Authorization: Bearer <token>
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // هنا يمكننا معالجة الأخطاء العامة (مثلاً إذا انتهت صلاحية الجلسة 401)
        print("API Error: ${e.response?.statusCode} - ${e.message}");
        return handler.next(e);
      },
    ));
  }

  // دوال مختصرة للطلبات (GET, POST, PUT, DELETE)
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}