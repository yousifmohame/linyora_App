import '../../../core/api/api_client.dart';
import '../../../models/section_model.dart';

class SectionService {
  final ApiClient _apiClient = ApiClient();

  Future<List<SectionModel>> getActiveSections() async {
    try {
      final response = await _apiClient.get('/sections/active'); //
      
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => SectionModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching sections: $e");
      return [];
    }
  }
}