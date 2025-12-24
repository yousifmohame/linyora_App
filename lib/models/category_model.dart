class CategoryModel {
  final int id;
  final String name;
  final String imageUrl;
  final String slug;
  final List<CategoryModel> children; // القائمة الفرعية

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.slug,
    this.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    var childrenList = <CategoryModel>[];
    if (json['children'] != null) {
      childrenList = (json['children'] as List)
          .map((i) => CategoryModel.fromJson(i))
          .toList();
    }

    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      imageUrl: (json['image_url'] ?? '').replaceAll('\\', '/'),
      slug: json['slug'] ?? '',
      children: childrenList,
    );
  }
}