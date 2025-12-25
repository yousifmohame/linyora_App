import '../../../core/api/api_client.dart';
import '../../../models/reel_model.dart';

class ReelsService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ReelModel>> getStyleTodayReels() async {
    try {
      final response = await _apiClient.get(
        '/reels',
      ); // تأكد من المسار (قد يكون /v1/reels)

      if (response.statusCode == 200) {
        final dynamic responseData = response.data;

        // 1. الحالة الأولى: الرد عبارة عن Map يحتوي على مفتاح 'reels' (كما في دالة getAllReels)
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('reels')) {
            final List list = responseData['reels'];
            return list.map((e) => ReelModel.fromJson(e)).toList();
          }
          // حالة احتياطية لو كان المفتاح data
          else if (responseData.containsKey('data')) {
            final List list = responseData['data'];
            return list.map((e) => ReelModel.fromJson(e)).toList();
          }
        }
        // 2. الحالة الثانية: الرد عبارة عن List مباشرة (كما في دالة getReelsForHomepage)
        else if (responseData is List) {
          return responseData.map((e) => ReelModel.fromJson(e)).toList();
        }

        // إذا لم نجد بيانات، نرجع قائمة فارغة
        return [];
      } else {
        throw Exception('Failed to load reels: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching reels: $e');
    }
  }
}
