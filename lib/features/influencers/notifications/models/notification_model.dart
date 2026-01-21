class NotificationModel {
  final int id;
  final String title;
  final String message; // غيرنا الاسم ليتطابق غالباً مع الباك اند
  final String type;
  final DateTime createdAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      // تأكد من أسماء الأعمدة في قاعدة بياناتك، هنا افترضنا أنها title و message
      // إذا كانت غير موجودة نضع نصاً افتراضياً لتجنب الكراش
      title: json['title'] ?? 'إشعار جديد', 
      message: json['message'] ?? '', 
      type: json['type'] ?? 'system',
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      // MySQL يرجع 1 للـ true و 0 للـ false
      isRead: (json['is_read'] == 1 || json['is_read'] == true),
    );
  }
}