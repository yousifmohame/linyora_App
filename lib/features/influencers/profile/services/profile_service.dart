import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/features/models/profile/models/profile_model.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<ProfileData> getProfile() async {
    final response = await _apiClient.get('/model/profile');
    return ProfileData.fromJson(response.data);
  }

  Future<void> updateProfile(ProfileData profile) async {
    await _apiClient.put('/model/profile', data: profile.toJson());
  }

  Future<String> uploadImage(File file) async {
    String fileName = file.path.split('/').last;
    String subType = fileName.split('.').last;
    
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType('image', subType),
      ),
    });

    final response = await _apiClient.post('/upload', data: formData);
    return response.data['imageUrl'];
  }
}