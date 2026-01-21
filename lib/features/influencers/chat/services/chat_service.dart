import 'dart:io';
import 'package:dio/dio.dart';
import 'package:linyora_project/core/api/api_client.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();

  // دالة إنشاء أو جلب محادثة (مطابقة لكود React)
  Future<int?> createConversation(int participantId) async {
    try {
      final response = await _apiClient.post(
        '/messages/conversations',
        data: {'participantId': participantId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // التأكد من تحويل الـ ID إلى int سواء جاء كنص أو رقم
        final id = response.data['conversationId'];
        return int.tryParse(id.toString());
      }
      return null;
    } catch (e) {
      print("Error creating conversation: $e");
      // طباعة تفاصيل الخطأ في الـ response للمساعدة في التتبع
      if (e is DioException) {
        print("Response: ${e.response?.data}");
      }
      return null;
    }
  }

  // جلب المحادثات
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _apiClient.get('/messages');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => Conversation.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching conversations: $e");
      return []; // إرجاع قائمة فارغة عند الخطأ
    }
  }

  // جلب الرسائل لمحادثة معينة
  Future<List<Message>> getMessages(int conversationId) async {
    try {
      final response = await _apiClient.get('/messages/$conversationId');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Message.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }

  // إرسال رسالة
  Future<void> sendMessage({
    required int receiverId,
    String? body,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    try {
      await _apiClient.post(
        '/messages',
        data: {
          'receiverId': receiverId,
          'body': body,
          'attachment_url': attachmentUrl,
          'attachment_type': attachmentType,
        },
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // رفع مرفق (صورة أو ملف)
  Future<Map<String, dynamic>?> uploadAttachment(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiClient.post(
        '/upload/attachment',
        data: formData,
        // تأكد أن ApiClient يدعم إرسال FormData أو استخدم Dio مباشرة هنا
      );

      return response
          .data; // { 'attachment_url': '...', 'attachment_type': 'image' }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // دالة لفتح محادثة مع مستخدم معين (إنشاء أو جلب الموجودة)
  Future<int?> initiateConversation(int targetUserId) async {
    try {
      // نفترض أن الباك إند لديه مسار لإنشاء محادثة بناء على معرف المستخدم
      final response = await _apiClient.post(
        '/messages/initiate',
        data: {'participant_id': targetUserId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // نفترض أن السيرفر يعيد الأيدي الخاص بالمحادثة
        return response.data['conversation_id'] ?? response.data['id'];
      }
      return null;
    } catch (e) {
      print("Error initiating conversation: $e");
      return null;
    }
  }
}
