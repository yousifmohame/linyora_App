import 'package:flutter/material.dart';
import 'package:linyora_project/features/trends/services/trend_service.dart';
import '../../../models/promoted_product_model.dart';


class TrendProvider extends ChangeNotifier {
  // إنشاء نسخة من السيرفس
  final TrendsService _service = TrendsService();

  // المتغيرات التي تحمل حالة الشاشة
  List<PromotedProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  // الوصول للمتغيرات من الخارج (Getters)
  List<PromotedProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // دالة جلب البيانات
  Future<void> fetchPromotedProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // تحديث الواجهة لبدء التحميل

    try {
      _products = await _service.getPromotedProducts();
    } catch (e) {
      print("TrendProvider Error: $e");
      _error = "حدث خطأ أثناء تحميل الترندات";
      _products = []; // تصفير القائمة في حال الخطأ
    } finally {
      _isLoading = false;
      notifyListeners(); // تحديث الواجهة لعرض البيانات أو الخطأ
    }
  }
}