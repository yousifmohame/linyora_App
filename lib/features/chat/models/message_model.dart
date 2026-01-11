class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String? body;
  final String? attachmentUrl;
  final String? attachmentType;
  bool isRead;
  final String createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.body,
    this.attachmentUrl,
    this.attachmentType,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      body: json['body'],
      attachmentUrl: json['attachment_url'],
      attachmentType: json['attachment_type'],

      // --- التعديل هنا ---
      // نقوم بفحص إذا كانت القيمة تساوي 1 أو true
      isRead: json['is_read'] == 1 || json['is_read'] == true,

      createdAt: json['created_at'],
    );
  }
}
