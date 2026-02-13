class Conversation {
  final int id;
  final int participantId;

  // جعلنا هذه الحقول غير final لتتمكن من تحديثها
  // عند وصول بيانات جديدة من السوكيت دون إعادة تحميل القائمة
  String? participantName;
  String? participantAvatar;
  String? lastMessage;
  bool isOnline; // ⚠️ حذفنا final
  String? lastSeen; // ⚠️ حذفنا final
  int unreadCount;

  Conversation({
    required this.id,
    required this.participantId,
    this.participantName,
    this.participantAvatar,
    this.lastMessage,
    required this.isOnline,
    this.lastSeen,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      // استخدام tryParse للأمان
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      participantId:
          int.tryParse(json['participantId']?.toString() ?? '0') ?? 0,

      participantName: json['participantName'],
      participantAvatar: json['participantAvatar'],
      lastMessage: json['lastMessage'],

      // ✅ المنطق الصحيح الذي كتبته أنت
      isOnline: json['is_online'] == 1 || json['is_online'] == true,

      lastSeen: json['last_seen'],

      // ✅ دعم التسميتين (CamelCase أو SnakeCase) حسب الباك إند
      unreadCount:
          int.tryParse(
            json['unreadCount']?.toString() ??
                json['unread_count']?.toString() ??
                '0',
          ) ??
          0,
    );
  }
}
