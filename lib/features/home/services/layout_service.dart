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
  dynamicSection, // للأقسام القادمة من الداتابيز
  bestSellers,
  topRated,
  topModels,
  topMerchants,
  divider,
}

// كلاس يمثل العنصر الواحد في القائمة
class HomeLayoutItem {
  final String id;
  final HomeItemType type;
  final dynamic data; // لحفظ بيانات القسم (SectionModel) إذا كان ديناميكياً

  HomeLayoutItem({
    required this.id,
    required this.type,
    this.data,
  });
}

class LayoutService {
  final ApiClient _apiClient = ApiClient();

  /// ✅ جلب الترتيب المحفوظ من السيرفر وربطه بالبيانات الحالية
  /// [availableSections]: قائمة الأقسام الحالية القادمة من SectionService
  Future<List<HomeLayoutItem>> getHomeLayout(List<SectionModel> availableSections) async {
    try {
      // 1. طلب الترتيب من الباك إند
      final response = await _apiClient.get('/layout/home');
      
      // إذا لم يكن هناك ترتيب محفوظ (null أو قائمة فارغة)، نرجع الترتيب الافتراضي
      if (response.data == null || (response.data is List && (response.data as List).isEmpty)) {
        return _getDefaultLayout(availableSections);
      }

      // 2. تحويل البيانات القادمة (List<String>) إلى List<HomeLayoutItem>
      List<dynamic> savedIds = response.data;
      List<HomeLayoutItem> layout = [];

      // قائمة مساعدة لتتبع الأقسام التي تمت إضافتها (لضمان عدم ضياع أقسام جديدة)
      Set<int> processedSectionIds = {};

      for (var id in savedIds) {
        String itemId = id.toString();

        // -- مطابقة المعرفات الثابتة --
        if (itemId == 'marquee') {
          layout.add(HomeLayoutItem(id: 'marquee', type: HomeItemType.marquee));
        } else if (itemId == 'stories') {
          layout.add(HomeLayoutItem(id: 'stories', type: HomeItemType.stories));
        } else if (itemId == 'banners') {
          layout.add(HomeLayoutItem(id: 'banners', type: HomeItemType.banners));
        } else if (itemId == 'flash_sale') {
          layout.add(HomeLayoutItem(id: 'flash_sale', type: HomeItemType.flashSale));
        } else if (itemId == 'categories') {
          layout.add(HomeLayoutItem(id: 'categories', type: HomeItemType.categories));
        } else if (itemId == 'new_arrivals') {
          layout.add(HomeLayoutItem(id: 'new_arrivals', type: HomeItemType.newArrivals));
        } else if (itemId == 'best_sellers') {
          layout.add(HomeLayoutItem(id: 'best_sellers', type: HomeItemType.bestSellers));
        } else if (itemId == 'top_rated') {
          layout.add(HomeLayoutItem(id: 'top_rated', type: HomeItemType.topRated));
        } else if (itemId == 'top_models') {
          layout.add(HomeLayoutItem(id: 'top_models', type: HomeItemType.topModels));
        } else if (itemId == 'top_merchants') {
          layout.add(HomeLayoutItem(id: 'top_merchants', type: HomeItemType.topMerchants));
        
        // -- مطابقة الأقسام الديناميكية (section_ID) --
        } else if (itemId.startsWith('section_')) {
          // استخراج رقم القسم من النص "section_5" -> 5
          int? sectionId = int.tryParse(itemId.split('_')[1]);
          if (sectionId != null) {
            // البحث عن القسم في القائمة المتوفرة حالياً
            try {
              final section = availableSections.firstWhere((s) => s.id == sectionId);
              layout.add(HomeLayoutItem(
                id: itemId,
                type: HomeItemType.dynamicSection,
                data: section,
              ));
              processedSectionIds.add(sectionId);
            } catch (e) {
              // القسم غير موجود (ربما تم حذفه)، نتجاهله
            }
          }
        }
      }

      // 3. (اختياري) إضافة أي أقسام جديدة ظهرت ولم تكن في الترتيب المحفوظ (تضاف في النهاية)
      for (var section in availableSections) {
        if (!processedSectionIds.contains(section.id)) {
          layout.add(HomeLayoutItem(
            id: 'section_${section.id}',
            type: HomeItemType.dynamicSection,
            data: section,
          ));
        }
      }

      return layout;

    } catch (e) {
      // في حالة الخطأ (مثلاً لا يوجد انترنت)، نعيد الترتيب الافتراضي
      print("Layout Load Error: $e");
      return _getDefaultLayout(availableSections);
    }
  }

  /// ✅ حفظ الترتيب الجديد في السيرفر (للأدمن)
  Future<void> saveLayoutOrder(List<HomeLayoutItem> items) async {
    try {
      // تحويل القائمة المعقدة إلى قائمة نصوص (IDs) فقط لإرسالها
      List<String> idsToSend = items.map((e) => e.id).toList();

      // إرسال المصفوفة مباشرة للباك إند
      await _apiClient.post('/layout/home', data: idsToSend);
      
      print("✅ Layout saved successfully: $idsToSend");
    } catch (e) {
      print("❌ Failed to save layout: $e");
      rethrow;
    }
  }

  /// 🔹 الترتيب الافتراضي (إذا لم يتم الحفظ مسبقاً)
  List<HomeLayoutItem> _getDefaultLayout(List<SectionModel> sections) {
    List<HomeLayoutItem> layout = [
      HomeLayoutItem(id: 'marquee', type: HomeItemType.marquee),
      HomeLayoutItem(id: 'stories', type: HomeItemType.stories),
      HomeLayoutItem(id: 'banners', type: HomeItemType.banners),
      HomeLayoutItem(id: 'flash_sale', type: HomeItemType.flashSale),
      HomeLayoutItem(id: 'categories', type: HomeItemType.categories),
      HomeLayoutItem(id: 'new_arrivals', type: HomeItemType.newArrivals),
    ];

    // دمج الأقسام الديناميكية في الوسط
    for (var section in sections) {
      layout.add(HomeLayoutItem(
        id: 'section_${section.id}',
        type: HomeItemType.dynamicSection,
        data: section,
      ));
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