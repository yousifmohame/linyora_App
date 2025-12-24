import '../../../core/api/api_client.dart';
import '../../../models/story_feed_item.dart';
import '../../../models/story_model.dart';

class StoriesService {
  final ApiClient _apiClient = ApiClient();

  // 1. جلب القائمة الرئيسية (الدوائر)
  Future<List<StoryFeedItem>> getStoriesFeed() async {
    try {
      final response = await _apiClient.get('/stories/feed'); //
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => StoryFeedItem.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching stories feed: $e");
      return [];
    }
  }

  // 2. جلب تفاصيل القصص عند النقر (User or Section)
  Future<List<StoryModel>> getStoriesById(int id, bool isSection) async {
    try {
      // النوع يحدد المسار في الباك إند
      String type = isSection ? 'section' : 'user';
      final response = await _apiClient.get('/stories/$id/view', queryParameters: {'type': type});
      
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => StoryModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching story details: $e");
      return [];
    }
  }

  // 3. تسجيل المشاهدة
  Future<void> markAsViewed(int storyId) async {
    try {
      await _apiClient.post('/stories/view', data: {'storyId': storyId});
    } catch (e) {
      print("Error marking view: $e");
    }
  }
}