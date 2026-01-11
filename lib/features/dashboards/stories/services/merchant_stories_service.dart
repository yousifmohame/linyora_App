import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // ✅ تأكد من وجود هذه المكتبة في pubspec.yaml
import '../../../../core/api/api_client.dart';
import '../models/merchant_story_model.dart';

class MerchantStoriesService {
  final ApiClient _apiClient = ApiClient();

  // 1. جلب القصص
  Future<List<MerchantStory>> getMyStories() async {
    try {
      final response = await _apiClient.get('/stories/my-stories');
      final List data =
          response.data is List ? response.data : response.data['data'] ?? [];
      return data.map((json) => MerchantStory.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching stories: $e");
      return [];
    }
  }

  // 2. إنشاء قصة جديدة (تم التعديل لتعمل بـ FormData)
  Future<bool> createStory({
    required String type, // 'image', 'video', 'text'
    File? file,
    String? textContent,
    String? backgroundColor,
    String? productId,
  }) async {
    try {
      // ✅ نستخدم FormData بدلاً من JSON لأن الباك إند يتوقع ملفاً في req.file
      final formData = FormData();

      // إضافة الحقول النصية
      formData.fields.add(MapEntry('type', type));
      formData.fields.add(
        MapEntry('background_color', backgroundColor ?? '#000000'),
      );

      if (textContent != null && textContent.isNotEmpty) {
        formData.fields.add(MapEntry('text_content', textContent));
      }

      if (productId != null) {
        formData.fields.add(MapEntry('product_id', productId));
      }

      // إضافة الملف (إذا وجد)
      if (file != null) {
        String fileName = file.path.split('/').last;

        // تحديد نوع الميديا بدقة
        MediaType contentType =
            type == 'video'
                ? MediaType('video', 'mp4')
                : MediaType('image', 'jpeg');

        formData.files.add(
          MapEntry(
            'media', // 👈 هام جداً: الاسم يجب أن يكون 'media' ليطابق upload.single('media') في الباك إند
            await MultipartFile.fromFile(
              file.path,
              filename: fileName,
              contentType: contentType,
            ),
          ),
        );
      }

      // إرسال الطلب
      final response = await _apiClient.post(
        '/stories',
        data: formData,
        // Dio سيقوم تلقائياً بضبط الهيدر لـ multipart/form-data
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        print("Create Story Error: ${e.response?.data}");
        throw e.response?.data['message'] ?? 'فشل نشر القصة';
      }
      throw e.toString();
    }
  }

  // 3. حذف قصة
  Future<bool> deleteStory(int id) async {
    try {
      await _apiClient.delete('/stories/$id');
      return true;
    } catch (e) {
      throw 'فشل حذف القصة';
    }
  }
}
