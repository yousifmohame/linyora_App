class ApiConstants {
  // الرابط الأساسي للـ API
  static const String baseUrl = "https://linyora.cloud/api";
  
  // مسارات المصادقة (بناءً على ملف routes/auth.js)
  static const String login = "/auth/login";
  static const String register = "/auth/register";
  static const String userProfile = "/users/profile"; // أو المسار المناسب لجلب بيانات المستخدم
}