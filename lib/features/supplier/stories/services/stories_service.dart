import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // لضبط نوع الميديا
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/supplier/stories/models/story_model.dart';

class StoriesService {
  final ApiClient _apiClient = ApiClient();

  // جلب قصصي
  Future<List<StoryModel>> getMyStories() async {
    try {
      final response = await _apiClient.get('/stories/my-stories');
      return (response.data as List)
          .map((e) => StoryModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('فشل جلب القصص');
    }
  }

  // حذف قصة
  Future<void> deleteStory(int id) async {
    await _apiClient.delete('/stories/$id');
  }

  // إنشاء قصة جديدة
  Future<void> createStory({
    required String type,
    File? file,
    String? textContent,
    String backgroundColor = '#000000',
  }) async {
    try {
      final Map<String, dynamic> dataMap = {
        'type': type,
        'background_color': backgroundColor,
      };

      if (textContent != null && textContent.isNotEmpty) {
        dataMap['text_content'] = textContent;
      }

      if (file != null) {
        String fileName = file.path.split('/').last;
        // تحديد نوع الملف (صورة أو فيديو)
        String mimeType = type == 'video' ? 'video' : 'image';
        String subType = fileName.split('.').last;

        dataMap['media'] = await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType(mimeType, subType),
        );
      }

      FormData formData = FormData.fromMap(dataMap);

      await _apiClient.post('/stories', data: formData);
    } catch (e) {
      throw Exception('فشل إنشاء القصة: $e');
    }
  }
}
