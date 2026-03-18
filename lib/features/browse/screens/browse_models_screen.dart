import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

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
  final ScrollController _scrollController = ScrollController();

  List<BrowsedModel> _allModels = [];
  List<BrowsedModel> _filteredModels = [];
  bool _isLoading = true;

  String _searchTerm = '';
  String _selectedCategory = 'all';
  String _sortBy = 'rating';
  List<String> _categories = ['all'];

  final Color _primaryColor = const Color(0xFFE11D48);
  final Color _darkColor = const Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _fetchModels();
  }

  Future<void> _fetchModels() async {
    setState(() => _isLoading = true);
    try {
      final models = await _service.getModels();
      final categorySet = <String>{'all'};
      for (var m in models) {
        categorySet.addAll(m.categories);
      }

      if (mounted) {
        setState(() {
          _allModels = models;
          _categories = categorySet.toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildStickySearchBar(l10n),
            _buildCategoriesBar(l10n),
          ]; // ✅ تمرير l10n
        },
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE11D48)),
                )
                : _filteredModels.isEmpty
                ? _buildEmptyState(l10n) // ✅ تمرير l10n
                : _buildImmersiveGrid(l10n), // ✅ تمرير l10n
      ),
    );
  }

  Widget _buildStickySearchBar(AppLocalizations l10n) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: const Color(0xFFFAFAFA),
      elevation: 0,
      toolbarHeight: 80,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            onChanged: (val) {
              _searchTerm = val;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: l10n.searchNameOrSpecialtyHint, // ✅ مترجم
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: _primaryColor),
              suffixIcon: IconButton(
                icon: const Icon(Icons.sort_rounded, color: Colors.grey),
                onPressed: () => _showSortPicker(l10n), // ✅ تمرير l10n
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesBar(AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        margin: const EdgeInsets.only(bottom: 10),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (c, i) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _selectedCategory == cat;
            return Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _applyFilters();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? _primaryColor : Colors.grey.shade200,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                            : [],
                  ),
                  child: Text(
                    cat == 'all' ? l10n.allCategory : cat, // ✅ مترجم
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImmersiveGrid(AppLocalizations l10n) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredModels.length,
      itemBuilder: (context, index) {
        return _buildPremiumCard(_filteredModels[index], l10n); // ✅ تمرير l10n
      },
    );
  }

  Widget _buildPremiumCard(BrowsedModel model, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModelProfileScreen(modelId: model.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'profile_${model.id}',
              child: CachedNetworkImage(
                imageUrl: model.profilePictureUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(color: Colors.grey[200]),
                errorWidget:
                    (c, u, e) => Container(
                      color: Colors.grey[100],
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[300],
                        size: 40,
                      ),
                    ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),

            if (model.isFeatured)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        l10n.featuredBadge, // ✅ مترجم
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _darkColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          model.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                      if (model.isVerified)
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.roleId == 3
                        ? l10n.fashionModelRole
                        : l10n.contentCreatorRole, // ✅ مترجم
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGlassStat(
                        Icons.star_rounded,
                        model.stats.rating.toString(),
                        Colors.amber,
                      ),
                      _buildGlassStat(
                        Icons.group_rounded,
                        model.stats.followers,
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassStat(IconData icon, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 20),
          Text(
            l10n.noResultsFoundMsg, // ✅ مترجم
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchTerm = '';
                _selectedCategory = 'all';
                _applyFilters();
              });
            },
            child: Text(
              l10n.resetBtn,
              style: TextStyle(color: _primaryColor),
            ), // ✅ مترجم
          ),
        ],
      ),
    );
  }

  void _showSortPicker(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.sortResultsByTitle, // ✅ مترجم
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSortOption(
                l10n.highestRatedSort,
                'rating',
                Icons.star_rounded,
              ), // ✅ مترجم
              _buildSortOption(
                l10n.mostFollowedSort,
                'followers',
                Icons.group_rounded,
              ), // ✅ مترجم
              _buildSortOption(
                l10n.nameAZSort,
                'name',
                Icons.sort_by_alpha_rounded,
              ), // ✅ مترجم
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      onTap: () {
        setState(() {
          _sortBy = value;
          _applyFilters();
        });
        Navigator.pop(context);
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? _primaryColor : Colors.grey[600],
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          isSelected ? Icon(Icons.check_circle, color: _primaryColor) : null,
    );
  }
}
