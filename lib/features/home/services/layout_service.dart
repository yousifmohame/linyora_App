import 'package:linyora_project/core/api/api_client.dart';
import 'package:linyora_project/models/section_model.dart';

// أنواع العناصر الممكنة في الصفحة الرئيسية
enum HomeItemType {
  marquee,
  stories,
  banners,
  flashSale,
  categories,
  newArrivals,
  dynamicSection,
  bestSellers,
  topRated,
  topModels,
  topMerchants,
  divider,
  linyoraPicks, // ✅
  seasonStyle, // ✅
}

class HomeLayoutItem {
  final String id;
  final HomeItemType type;
  final dynamic data;

  HomeLayoutItem({required this.id, required this.type, this.data});
}

class LayoutService {
  final ApiClient _apiClient = ApiClient();

  Future<List<HomeLayoutItem>> getHomeLayout(
    List<SectionModel> availableSections,
  ) async {
    try {
      final response = await _apiClient.get('/layout/home');

      if (response.data == null ||
          (response.data is List && (response.data as List).isEmpty)) {
        return _getDefaultLayout(availableSections);
      }

      List<dynamic> savedIds = response.data;
      List<HomeLayoutItem> layout = [];
      Set<int> processedSectionIds = {};

      for (var id in savedIds) {
        String itemId = id.toString();

        if (itemId == 'marquee') {
          layout.add(HomeLayoutItem(id: 'marquee', type: HomeItemType.marquee));
        } else if (itemId == 'stories') {
          layout.add(HomeLayoutItem(id: 'stories', type: HomeItemType.stories));
        } else if (itemId == 'banners') {
          layout.add(HomeLayoutItem(id: 'banners', type: HomeItemType.banners));
        } else if (itemId == 'flash_sale') {
          layout.add(
            HomeLayoutItem(id: 'flash_sale', type: HomeItemType.flashSale),
          );
        } else if (itemId == 'categories') {
          layout.add(
            HomeLayoutItem(id: 'categories', type: HomeItemType.categories),
          );
        } else if (itemId == 'new_arrivals') {
          layout.add(
            HomeLayoutItem(id: 'new_arrivals', type: HomeItemType.newArrivals),
          );

          // ✅ 1. إضافة التحقق من مختارات لينيورا
        } else if (itemId == 'linyora_picks') {
          layout.add(
            HomeLayoutItem(
              id: 'linyora_picks',
              type: HomeItemType.linyoraPicks,
            ),
          );

          // ✅ 2. إضافة التحقق من ستايل الموسم
        } else if (itemId == 'season_style') {
          layout.add(
            HomeLayoutItem(id: 'season_style', type: HomeItemType.seasonStyle),
          );
        } else if (itemId == 'best_sellers') {
          layout.add(
            HomeLayoutItem(id: 'best_sellers', type: HomeItemType.bestSellers),
          );
        } else if (itemId == 'top_rated') {
          layout.add(
            HomeLayoutItem(id: 'top_rated', type: HomeItemType.topRated),
          );
        } else if (itemId == 'top_models') {
          layout.add(
            HomeLayoutItem(id: 'top_models', type: HomeItemType.topModels),
          );
        } else if (itemId == 'top_merchants') {
          layout.add(
            HomeLayoutItem(
              id: 'top_merchants',
              type: HomeItemType.topMerchants,
            ),
          );

          // الأقسام الديناميكية
        } else if (itemId.startsWith('section_')) {
          int? sectionId = int.tryParse(itemId.split('_')[1]);
          if (sectionId != null) {
            try {
              final section = availableSections.firstWhere(
                (s) => s.id == sectionId,
              );
              layout.add(
                HomeLayoutItem(
                  id: itemId,
                  type: HomeItemType.dynamicSection,
                  data: section,
                ),
              );
              processedSectionIds.add(sectionId);
            } catch (e) {
              // القسم محذوف
            }
          }
        }
      }

      // إضافة الأقسام الجديدة التي لم تكن في الترتيب
      for (var section in availableSections) {
        if (!processedSectionIds.contains(section.id)) {
          layout.add(
            HomeLayoutItem(
              id: 'section_${section.id}',
              type: HomeItemType.dynamicSection,
              data: section,
            ),
          );
        }
      }

      return layout;
    } catch (e) {
      print("Layout Load Error: $e");
      return _getDefaultLayout(availableSections);
    }
  }

  Future<void> saveLayoutOrder(List<HomeLayoutItem> items) async {
    try {
      List<String> idsToSend = items.map((e) => e.id).toList();
      await _apiClient.post('/layout/home', data: idsToSend);
      print("✅ Layout saved successfully: $idsToSend");
    } catch (e) {
      print("❌ Failed to save layout: $e");
      rethrow;
    }
  }

  List<HomeLayoutItem> _getDefaultLayout(List<SectionModel> sections) {
    List<HomeLayoutItem> layout = [
      HomeLayoutItem(id: 'marquee', type: HomeItemType.marquee),
      HomeLayoutItem(id: 'stories', type: HomeItemType.stories),
      HomeLayoutItem(id: 'banners', type: HomeItemType.banners),
      HomeLayoutItem(id: 'flash_sale', type: HomeItemType.flashSale),
      HomeLayoutItem(id: 'categories', type: HomeItemType.categories),
      // ✅ 3. إضافتهم في الترتيب الافتراضي
      HomeLayoutItem(id: 'linyora_picks', type: HomeItemType.linyoraPicks),
      HomeLayoutItem(id: 'new_arrivals', type: HomeItemType.newArrivals),
      // ✅
      HomeLayoutItem(id: 'season_style', type: HomeItemType.seasonStyle),
    ];

    for (var section in sections) {
      layout.add(
        HomeLayoutItem(
          id: 'section_${section.id}',
          type: HomeItemType.dynamicSection,
          data: section,
        ),
      );
    }

    layout.addAll([
      HomeLayoutItem(id: 'best_sellers', type: HomeItemType.bestSellers),
      HomeLayoutItem(id: 'top_rated', type: HomeItemType.topRated),
      HomeLayoutItem(id: 'top_models', type: HomeItemType.topModels),
      HomeLayoutItem(id: 'top_merchants', type: HomeItemType.topMerchants),
    ]);

    return layout;
  }
}
