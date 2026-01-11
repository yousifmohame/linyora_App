class Conversation {
  final int id;
  final int participantId;
  final String? participantName;
  final String? participantAvatar;
  String? lastMessage;
  final bool isOnline;
  final String? lastSeen;
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
      id: json['id'],
      participantId: json['participantId'] ?? 0,
      participantName: json['participantName'],
      participantAvatar: json['participantAvatar'],
      lastMessage: json['lastMessage'],

      // --- التعديل هنا ---
      // نقوم بفحص إذا كانت القيمة تساوي 1 (رقم) أو true (بوليان)
      isOnline: json['is_online'] == 1 || json['is_online'] == true,

      lastSeen: json['last_seen'],
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}
