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

  // حالة التحميل والبيانات
  bool _isLoading = true;
  FilterOptionsModel _filterOptions = FilterOptionsModel();

  // قيم الفلاتر المختارة
  RangeValues _priceRange = const RangeValues(
    0,
    5000,
  ); // القيمة القصوى الافتراضية
  List<String> _selectedBrands = [];
  int? _selectedRating;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // 1. استعادة الفلاتر الحالية (من القيم الممررة)
    if (widget.currentFilters['price_min'] != null) {
      _priceRange = RangeValues(
        double.tryParse(widget.currentFilters['price_min'].toString()) ?? 0,
        double.tryParse(widget.currentFilters['price_max'].toString()) ?? 5000,
      );
    }
    if (widget.currentFilters['brands'] != null) {
      // التعامل مع الماركات سواء كانت String مفصولة بفواصل أو List
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

    // 2. جلب خيارات الفلترة من السيرفر
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

  void _apply() {
    final filters = <String, dynamic>{
      'price_min': _priceRange.start.round(),
      'price_max': _priceRange.end.round(),
      if (_selectedBrands.isNotEmpty)
        'brands': _selectedBrands, // قد تحتاج join(',') حسب الباك إند
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

  // دالة ذكية لتحويل أسماء الألوان إلى ألوان حقيقية
  Color _parseColor(String colorName) {
    final name = colorName.trim().toLowerCase();

    // دعم Hex Codes
    if (name.startsWith('#')) {
      try {
        final buffer = StringBuffer();
        if (name.length == 7) buffer.write('ff');
        buffer.write(name.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return Colors.grey;
      }
    }

    const Map<String, Color> colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'black': Colors.black,
      'white': Colors.white,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'brown': Colors.brown,
      'grey': Colors.grey,
      'gold': Color(0xFFFFD700),
      'silver': Color(0xFFC0C0C0),
      'beige': Color(0xFFF5F5DC),
      'navy': Color(0xFF000080),
      'teal': Colors.teal,
    };
    return colorMap[name] ?? Colors.grey.shade300;
  }

  Color _getCheckColor(Color bg) =>
      bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تصفية النتائج",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text(
                      "مسح الكل",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // --- Loading State ---
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                ),
              )
            else
              // --- Content ---
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. السعر
                    _buildSectionTitle("نطاق السعر"),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 5000,
                      divisions: 100,
                      activeColor: Colors.pink,
                      inactiveColor: Colors.pink.withOpacity(0.2),
                      labels: RangeLabels(
                        "${_priceRange.start.toInt()} ر.س",
                        "${_priceRange.end.toInt()} ر.س",
                      ),
                      onChanged:
                          (values) => setState(() => _priceRange = values),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${_priceRange.start.toInt()} ر.س",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          "${_priceRange.end.toInt()} ر.س",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. الماركات (من API)
                    if (_filterOptions.brands.isNotEmpty) ...[
                      _buildSectionTitle("الماركة"),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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
                                selectedColor: Colors.pink.withOpacity(0.1),
                                checkmarkColor: Colors.pink,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.pink : Colors.black87,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? Colors.pink
                                            : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 3. التقييم
                    _buildSectionTitle("التقييم"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:
                          [5, 4, 3, 2, 1].map((rating) {
                            final isSelected = _selectedRating == rating;
                            return InkWell(
                              onTap:
                                  () => setState(
                                    () =>
                                        _selectedRating =
                                            isSelected ? null : rating,
                                  ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.amber.withOpacity(0.2)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.amber
                                            : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "$rating",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // 4. الألوان (من API)
                    if (_filterOptions.colors.isNotEmpty) ...[
                      _buildSectionTitle("اللون"),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            _filterOptions.colors.map((colorName) {
                              final isSelected = _selectedColor == colorName;
                              final color = _parseColor(colorName);
                              return GestureDetector(
                                onTap:
                                    () => setState(
                                      () =>
                                          _selectedColor =
                                              isSelected ? null : colorName,
                                    ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Colors.pink
                                                  : Colors.grey.shade300,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: Colors.pink.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                        ],
                                      ),
                                      child:
                                          isSelected
                                              ? Icon(
                                                Icons.check,
                                                size: 20,
                                                color: _getCheckColor(color),
                                              )
                                              : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      colorName,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

            // --- Footer ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "عرض النتائج",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}
