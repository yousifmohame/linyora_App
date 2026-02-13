import 'package:flutter/material.dart';
import 'package:linyora_project/features/products/services/product_service.dart';
import 'package:linyora_project/models/filter_options_model.dart';

class ProductFilterDrawer extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final Map<String, dynamic> currentFilters;

  const ProductFilterDrawer({
    Key? key,
    required this.onApplyFilters,
    required this.currentFilters,
  }) : super(key: key);

  @override
  State<ProductFilterDrawer> createState() => _ProductFilterDrawerState();
}

class _ProductFilterDrawerState extends State<ProductFilterDrawer> {
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  FilterOptionsModel _filterOptions = FilterOptionsModel();

  RangeValues _priceRange = const RangeValues(0, 5000);
  List<String> _selectedBrands = [];
  int? _selectedRating;
  String? _selectedColor;

  // خريطة الألوان الذكية (إنجليزي + عربي)
  static const Map<String, Color> _smartColorMap = {
    // English
    'white': Colors.white,
    'black': Colors.black,
    'red': Colors.red,
    'green': Colors.green,
    'blue': Colors.blue,
    'yellow': Colors.yellow,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'brown': Colors.brown,
    'grey': Colors.grey,
    'gray': Colors.grey,
    'gold': Color(0xFFFFD700),
    'silver': Color(0xFFC0C0C0),
    'beige': Color(0xFFF5F5DC),
    'navy': Color(0xFF000080),
    'teal': Colors.teal,
    'cyan': Colors.cyan,
    'maroon': Color(0xFF800000),
    'olive': Color(0xFF808000),
    'lime': Colors.lime,
    'indigo': Colors.indigo,
    'violet': Color(0xFFEE82EE),

    // Arabic
    'أبيض': Colors.white,
    'ابيض': Colors.white,
    'أسود': Colors.black,
    'اسود': Colors.black,
    'أحمر': Colors.red,
    'احمر': Colors.red,
    'أخضر': Colors.green,
    'اخضر': Colors.green,
    'أزرق': Colors.blue,
    'ازرق': Colors.blue,
    'أصفر': Colors.yellow,
    'اصفر': Colors.yellow,
    'برتقالي': Colors.orange,
    'بني': Colors.brown,
    'رمادي': Colors.grey,
    'رصاصي': Colors.grey,
    'زهري': Colors.pink,
    'وردي': Colors.pink,
    'بنفسجي': Colors.purple,
    'أرجواني': Colors.purple,
    'ذهبي': Color(0xFFFFD700),
    'فضي': Color(0xFFC0C0C0),
    'بيج': Color(0xFFF5F5DC),
    'كحلي': Color(0xFF000080),
    'سماوي': Colors.cyan,
    'نبيتي': Color(0xFF800000),
    'زيتي': Color(0xFF808000),
    'ليموني': Colors.lime,
  };

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // 1. استعادة الفلاتر
    if (widget.currentFilters['price_min'] != null) {
      _priceRange = RangeValues(
        double.tryParse(widget.currentFilters['price_min'].toString()) ?? 0,
        double.tryParse(widget.currentFilters['price_max'].toString()) ?? 5000,
      );
    }
    if (widget.currentFilters['brands'] != null) {
      var brandsData = widget.currentFilters['brands'];
      if (brandsData is List) {
        _selectedBrands = List<String>.from(brandsData);
      } else if (brandsData is String) {
        _selectedBrands = brandsData.split(',');
      }
    }
    _selectedRating = int.tryParse(
      widget.currentFilters['rating']?.toString() ?? '',
    );
    _selectedColor = widget.currentFilters['color'];

    // 2. جلب الخيارات
    try {
      final options = await _productService.getFilterOptions();
      if (mounted) {
        setState(() {
          _filterOptions = options;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ الدالة الذكية الجديدة لتحليل الألوان
  Color _parseColor(String input) {
    if (input.isEmpty) return Colors.transparent;

    String cleanInput = input.trim().toLowerCase();

    // 1. Hex Code (#RRGGBB)
    if (cleanInput.startsWith('#')) {
      try {
        final buffer = StringBuffer();
        if (cleanInput.length == 7) buffer.write('ff'); // Add Alpha if missing
        buffer.write(cleanInput.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return Colors.grey.shade300; // Fallback
      }
    }

    // 2. البحث في الخريطة الذكية
    if (_smartColorMap.containsKey(cleanInput)) {
      return _smartColorMap[cleanInput]!;
    }

    // 3. Fallback ذكي: توليد لون من النص (Hash) إذا لم يكن معروفاً
    // هذا مفيد للألوان الغريبة التي لا توجد في القائمة
    /*
    int hash = cleanInput.codeUnits.fold(0, (p, c) => p + c);
    return Colors.primaries[hash % Colors.primaries.length];
    */

    return Colors.grey.shade200; // لون افتراضي للمجهول
  }

  // ✅ دالة ذكية لتحديد لون علامة الصح (أبيض أو أسود) بناءً على سطوع الخلفية
  Color _getContrastColor(Color color) {
    // حساب السطوع (Luminance)
    // 0.0 = أسود حالك، 1.0 = أبيض ناصع
    // العتبة 0.5 جيدة، لكن 0.6 تعطي نتائج أفضل للعين البشرية
    return color.computeLuminance() > 0.6 ? Colors.black87 : Colors.white;
  }

  void _apply() {
    final filters = <String, dynamic>{
      'price_min': _priceRange.start.round(),
      'price_max': _priceRange.end.round(),
      if (_selectedBrands.isNotEmpty) 'brands': _selectedBrands,
      if (_selectedRating != null) 'rating': _selectedRating,
      if (_selectedColor != null) 'color': _selectedColor,
    };
    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _priceRange = const RangeValues(0, 5000);
      _selectedBrands = [];
      _selectedRating = null;
      _selectedColor = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.85, // عرض مناسب
      child: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تصفية النتائج",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(
                        Icons.refresh,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        "إعادة تعيين",
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: Colors.red.withOpacity(0.05),
                      ),
                    ),
                ],
              ),
            ),

            // --- Content ---
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: Text("جاري تحميل الخيارات..."))
                      : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // 1. السعر
                          _buildSectionHeader(
                            "السعر",
                            "${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} ر.س",
                          ),
                          const SizedBox(height: 10),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.pink,
                              inactiveTrackColor: Colors.pink.withOpacity(0.1),
                              thumbColor: Colors.white,
                              overlayColor: Colors.pink.withOpacity(0.2),
                              valueIndicatorColor: Colors.pink,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                                elevation: 4,
                              ),
                              trackHeight: 4,
                            ),
                            child: RangeSlider(
                              values: _priceRange,
                              min: 0,
                              max: 5000,
                              divisions: 50,
                              labels: RangeLabels(
                                "${_priceRange.start.toInt()}",
                                "${_priceRange.end.toInt()}",
                              ),
                              onChanged:
                                  (values) =>
                                      setState(() => _priceRange = values),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // 2. الماركات
                          if (_filterOptions.brands.isNotEmpty) ...[
                            _buildSectionHeader(
                              "الماركات",
                              _selectedBrands.isNotEmpty
                                  ? "${_selectedBrands.length} محدد"
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 10,
                              children:
                                  _filterOptions.brands.map((brand) {
                                    final isSelected = _selectedBrands.contains(
                                      brand,
                                    );
                                    return FilterChip(
                                      label: Text(brand),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          selected
                                              ? _selectedBrands.add(brand)
                                              : _selectedBrands.remove(brand);
                                        });
                                      },
                                      backgroundColor: Colors.white,
                                      selectedColor: Colors.pink.shade50,
                                      checkmarkColor: Colors.pink,
                                      side: BorderSide(
                                        color:
                                            isSelected
                                                ? Colors.pink
                                                : Colors.grey.shade300,
                                      ),
                                      labelStyle: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.pink
                                                : Colors.black87,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 30),
                          ],

                          // 3. التقييم
                          _buildSectionHeader("التقييم", null),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                int star = 5 - index; // 5, 4, 3...
                                bool isSelected = _selectedRating == star;
                                return InkWell(
                                  onTap:
                                      () => setState(
                                        () =>
                                            _selectedRating =
                                                isSelected ? null : star,
                                      ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.amber.withOpacity(0.15)
                                              : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.amber
                                                : Colors.grey.shade200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          "$star",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color:
                                                isSelected
                                                    ? Colors.black87
                                                    : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.star_rounded,
                                          size: 18,
                                          color:
                                              isSelected
                                                  ? Colors.amber
                                                  : Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 30),

                          // 4. الألوان (الذكية)
                          if (_filterOptions.colors.isNotEmpty) ...[
                            _buildSectionHeader("اللون", _selectedColor),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children:
                                  _filterOptions.colors.map((colorName) {
                                    final isSelected =
                                        _selectedColor == colorName;
                                    final color = _parseColor(colorName);
                                    final checkColor = _getContrastColor(color);

                                    return GestureDetector(
                                      onTap:
                                          () => setState(
                                            () =>
                                                _selectedColor =
                                                    isSelected
                                                        ? null
                                                        : colorName,
                                          ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    isSelected
                                                        ? Colors.pink
                                                        : Colors.grey.shade300,
                                                width: isSelected ? 2.5 : 1,
                                              ),
                                              boxShadow:
                                                  isSelected
                                                      ? [
                                                        BoxShadow(
                                                          color: color
                                                              .withOpacity(0.4),
                                                          blurRadius: 8,
                                                          spreadRadius: 2,
                                                        ),
                                                      ]
                                                      : [],
                                            ),
                                            child:
                                                isSelected
                                                    ? Icon(
                                                      Icons.check,
                                                      size: 24,
                                                      color: checkColor,
                                                    )
                                                    : null,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            colorName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  isSelected
                                                      ? Colors.black87
                                                      : Colors.grey.shade500,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                          const SizedBox(height: 50), // مساحة إضافية في الأسفل
                        ],
                      ),
            ),

            // --- Footer ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // لون أسود فخم
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "تطبيق الفلتر",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle_outline, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (subtitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                color: Colors.pink.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
