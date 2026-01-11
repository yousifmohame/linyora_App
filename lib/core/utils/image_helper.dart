class ImageHelper {
  static String getValidUrl(String? url) {
    if (url == null || url.isEmpty) {
      // صورة افتراضية في حالة عدم وجود صورة
      return "https://placehold.co/400"; 
    }

    // 1. إصلاح الشرطات المائلة المعكوسة (مشكلة ويندوز)
    String cleanUrl = url.replaceAll('\\', '/');

    // 2. إذا كان الرابط كاملاً (Cloudinary)، أعده كما هو
    if (cleanUrl.startsWith('http')) {
      return cleanUrl;
    }

    // 3. إذا كان مساراً محلياً، أضف الدومين الخاص بك
    // تأكد أن الرابط لا يبدأ بـ / لكي لا تتكرر
    if (cleanUrl.startsWith('/')) {
      cleanUrl = cleanUrl.substring(1);
    }
    
    return "https://linyora.cloud/$cleanUrl";
  }
}