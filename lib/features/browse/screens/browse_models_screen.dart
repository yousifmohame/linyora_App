import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // للأيقونات الاجتماعية
import 'package:linyora_project/features/browse/screens/model_profile_screen.dart';
import '../models/browsed_model.dart';
import '../services/browse_service.dart';

class BrowseModelsScreen extends StatefulWidget {
  const BrowseModelsScreen({Key? key}) : super(key: key);

  @override
  State<BrowseModelsScreen> createState() => _BrowseModelsScreenState();
}

class _BrowseModelsScreenState extends State<BrowseModelsScreen> {
  final BrowseService _service = BrowseService();

  List<BrowsedModel> _allModels = [];
  List<BrowsedModel> _filteredModels = [];
  bool _isLoading = true;

  // Filters State
  String _searchTerm = '';
  String _selectedCategory = 'all';
  String _sortBy = 'name'; // name, rating, followers
  List<String> _categories = ['all'];

  @override
  void initState() {
    super.initState();
    _fetchModels();
  }

  Future<void> _fetchModels() async {
    setState(() => _isLoading = true);
    final models = await _service.getModels();

    // استخراج التصنيفات
    final categorySet = <String>{'all'};
    for (var m in models) {
      categorySet.addAll(m.categories);
    }

    if (mounted) {
      setState(() {
        _allModels = models;
        _categories = categorySet.toList();
        _applyFilters(); // تطبيق الفلاتر المبدئية
        _isLoading = false;
      });
    }
  }

  // ✅ منطق الفلترة والترتيب (مثل useMemo في React)
  void _applyFilters() {
    List<BrowsedModel> temp =
        _allModels.where((model) {
          final matchesSearch =
              model.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
              model.bio.toLowerCase().contains(_searchTerm.toLowerCase()) ||
              model.categories.any(
                (c) => c.toLowerCase().contains(_searchTerm.toLowerCase()),
              );

          final matchesCategory =
              _selectedCategory == 'all' ||
              model.categories.contains(_selectedCategory);

          return matchesSearch && matchesCategory;
        }).toList();

    // الترتيب
    temp.sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          return b.stats.rating.compareTo(a.stats.rating);
        case 'followers':
          return _parseFollowers(
            b.stats.followers,
          ).compareTo(_parseFollowers(a.stats.followers));
        case 'name':
        default:
          return a.name.compareTo(b.name);
      }
    });

    setState(() {
      _filteredModels = temp;
    });
  }

  // دالة مساعدة لتحويل 10K إلى 10000 للترتيب
  int _parseFollowers(String followers) {
    String clean = followers.toUpperCase().replaceAll(',', '');
    double multiplier = 1;
    if (clean.contains('K')) {
      multiplier = 1000;
      clean = clean.replaceAll('K', '');
    } else if (clean.contains('M')) {
      multiplier = 1000000;
      clean = clean.replaceAll('M', '');
    }
    return ((double.tryParse(clean) ?? 0) * multiplier).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF1F2),
              Color(0xFFF3E8FF),
            ], // Rose-50 to Purple-50
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Header & Search & Filters
              _buildHeaderSection(),

              // 2. Results List
              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF43F5E),
                          ),
                        )
                        : _filteredModels.isEmpty
                        ? _buildEmptyState()
                        : _buildModelsGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Title
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group, color: Color(0xFFE11D48)),
              SizedBox(width: 8),
              Text(
                "استكشف المواهب",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) {
                _searchTerm = val;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: "ابحث عن اسم، تخصص، أو كلمة مفتاحية...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Category Dropdown
                _buildFilterChip(
                  label:
                      "التصنيف: ${_selectedCategory == 'all' ? 'الكل' : _selectedCategory}",
                  icon: Icons.filter_list,
                  isActive: _selectedCategory != 'all',
                  onTap: () => _showCategoryPicker(),
                ),
                const SizedBox(width: 8),
                // Sort Dropdown
                _buildFilterChip(
                  label: "ترتيب حسب: ${_getSortLabel(_sortBy)}",
                  icon: Icons.sort,
                  isActive: _sortBy != 'name',
                  onTap: () => _showSortPicker(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          // Results Count
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "تم العثور على ${_filteredModels.length} نتيجة",
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // عمودين
        childAspectRatio: 0.60, // نسبة الطول للعرض (بطاقة طويلة)
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredModels.length,
      itemBuilder: (context, index) {
        return _buildModelCard(_filteredModels[index]);
      },
    );
  }

  Widget _buildModelCard(BrowsedModel model) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. Cover & Avatar Area
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Background Gradient
              Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF1F2), Color(0xFFF3E8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Featured Badge
              if (model.isFeatured)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, size: 10, color: Colors.white),
                        SizedBox(width: 2),
                        Text(
                          "مميز",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Verified Badge (Next to Avatar logic handled below)

              // Avatar
              Positioned(
                bottom: -30,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            (model.profilePictureUrl != null &&
                                    model.profilePictureUrl!.isNotEmpty)
                                ? CachedNetworkImageProvider(
                                  model.profilePictureUrl!,
                                )
                                : null,
                        child:
                            (model.profilePictureUrl == null ||
                                    model.profilePictureUrl!.isEmpty)
                                ? Text(
                                  model.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.purple,
                                  ),
                                )
                                : null,
                      ),
                    ),
                    if (model.isVerified)
                      const Positioned(
                        bottom: 2,
                        right: 2,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 35), // Space for Avatar
          // 2. Info Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  // Name & Role
                  Text(
                    model.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.pink.shade100),
                    ),
                    child: Text(
                      model.roleId == 3 ? "عارضة أزياء" : "مؤثرة",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.pink.shade800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Bio
                  Text(
                    model.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),

                  // Categories Chips
                  if (model.categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            model.categories
                                .take(2)
                                .map(
                                  (cat) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),

                  const Spacer(),

                  // Stats Grid
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          model.stats.followers,
                          "متابع",
                          Icons.group,
                        ),
                        _buildStatItem(
                          model.stats.rating.toString(),
                          "تقييم",
                          Icons.star,
                          iconColor: Colors.amber,
                        ),
                      ],
                    ),
                  ),

                  // Social Icons
                  if (model.socialLinks != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (model.socialLinks!.instagram != null)
                            _socialIcon(
                              FontAwesomeIcons.instagram,
                              Colors.pink,
                            ),
                          if (model.socialLinks!.twitter != null)
                            _socialIcon(FontAwesomeIcons.twitter, Colors.blue),
                          if (model.socialLinks!.facebook != null)
                            _socialIcon(
                              FontAwesomeIcons.facebook,
                              Colors.blue.shade800,
                            ),
                        ],
                      ),
                    ),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ModelProfileScreen(modelId: model.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shadowColor: Colors.transparent,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF43F5E), Color(0xFF9333EA)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "عرض الملف",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon, {
    Color iconColor = Colors.grey,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: iconColor),
            const SizedBox(width: 2),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
      ],
    );
  }

  Widget _socialIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.pink.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.pink.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.pink.shade600 : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.pink.shade700 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_off, size: 40, color: Colors.pink.shade300),
          ),
          const SizedBox(height: 16),
          const Text(
            "لا توجد نتائج مطابقة",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _searchTerm = '';
                _selectedCategory = 'all';
                _applyFilters();
              });
            },
            child: const Text("إعادة تعيين الفلاتر"),
          ),
        ],
      ),
    );
  }

  // Bottom Sheets for Pickers
  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          children: [
            const Text(
              "اختر التصنيف",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _categories
                      .map(
                        (cat) => ChoiceChip(
                          label: Text(cat == 'all' ? 'الكل' : cat),
                          selected: _selectedCategory == cat,
                          selectedColor: Colors.pink.shade100,
                          onSelected: (val) {
                            setState(() {
                              _selectedCategory = cat;
                              _applyFilters();
                            });
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
            ),
          ],
        );
      },
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "ترتيب النتائج حسب",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text("الاسم"),
                trailing:
                    _sortBy == 'name'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'name';
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text("التقييم"),
                trailing:
                    _sortBy == 'rating'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'rating';
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text("عدد المتابعين"),
                trailing:
                    _sortBy == 'followers'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'followers';
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'rating':
        return 'التقييم';
      case 'followers':
        return 'المتابعين';
      default:
        return 'الاسم';
    }
  }
}
