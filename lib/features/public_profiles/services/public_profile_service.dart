import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../models/public_profile_models.dart';

class PublicProfileService {
  final ApiClient _apiClient = ApiClient();

  // جلب بروفايل التاجر
  Future<PublicMerchantProfile> getMerchantProfile(String id) async {
    try {
      final response = await _apiClient.get('/merchants/public-profile/$id');
      return PublicMerchantProfile.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load merchant profile');
    }
  }

  // جلب بروفايل المودل
  // أو استخدم المسار المناسب الذي يرجع نفس هيكل ModelProfileData في React
  Future<PublicModelProfile> getModelProfile(String id) async {
    try {
      final response = await _apiClient.get('/users/$id/profile');
      return PublicModelProfile.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load model profile');
    }
  }

  // متابعة / إلغاء متابعة
  Future<bool> toggleFollow(int userId, bool isCurrentlyFollowing) async {
    try {
      if (isCurrentlyFollowing) {
        await _apiClient.delete('/users/$userId/follow');
        return false;
      } else {
        await _apiClient.post('/users/$userId/follow', data: {});
        return true;
      }
    } catch (e) {
      rethrow;
    }
  }
}
