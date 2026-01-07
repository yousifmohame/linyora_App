class FilterOptionsModel {
  final List<String> brands;
  final List<String> colors;
  final List<String> sizes;

  FilterOptionsModel({
    this.brands = const [],
    this.colors = const [],
    this.sizes = const [],
  });

  factory FilterOptionsModel.fromJson(Map<String, dynamic> json) {
    return FilterOptionsModel(
      brands: List<String>.from(json['brands'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      sizes: List<String>.from(json['sizes'] ?? []),
    );
  }
}