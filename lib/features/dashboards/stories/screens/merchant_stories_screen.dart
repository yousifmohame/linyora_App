import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../models/merchant_story_model.dart';
import '../services/merchant_stories_service.dart';
import 'create_story_modal.dart';

const List<Map<String, dynamic>> kStoryColors = [
  {'value': '#000000', 'color': Colors.black, 'label': 'أسود'},
  {'value': '#3B82F6', 'color': Color(0xFF3B82F6), 'label': 'أزرق'},
  {'value': '#10B981', 'color': Color(0xFF10B981), 'label': 'أخضر'},
  {'value': '#8B5CF6', 'color': Color(0xFF8B5CF6), 'label': 'بنفسجي'},
  {'value': '#EF4444', 'color': Color(0xFFEF4444), 'label': 'أحمر'},
  {'value': '#F59E0B', 'color': Color(0xFFF59E0B), 'label': 'ذهبي'},
];

class MerchantStoriesScreen extends StatefulWidget {
  const MerchantStoriesScreen({Key? key}) : super(key: key);

  @override
  State<MerchantStoriesScreen> createState() => _MerchantStoriesScreenState();
}

class _MerchantStoriesScreenState extends State<MerchantStoriesScreen> {
  final MerchantStoriesService _service = MerchantStoriesService();
  List<MerchantStory> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    setState(() => _isLoading = true);
    final stories = await _service.getMyStories();
    if (mounted) {
      setState(() {
        _stories = stories;
        _isLoading = false;
      });
    }
  }

  void _showCreateStoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateStoryModal(),
    ).then((value) {
      if (value == true) {
        _fetchStories();
      }
    });
  }

  // ✅ تمرير l10n
  Future<void> _confirmDelete(int id, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  l10n.deleteStoryTitle, // ✅ مترجم (سابقاً)
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              l10n.deleteStoryConfirmDesc, // ✅ مترجم
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  l10n.cancelBtn,
                  style: const TextStyle(color: Colors.grey),
                ), // ✅ مترجم
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.delete), // ✅ مترجم
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final previousStories = List<MerchantStory>.from(_stories);
    setState(() {
      _stories.removeWhere((s) => s.id == id);
    });

    try {
      await _service.deleteStory(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.storyDeletedSuccessfullyMsg), // ✅ مترجم
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      setState(() => _stories = previousStories);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToDeleteStoryMsg), // ✅ مترجم
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n.storeStories, // ✅ مترجم (سابقاً)
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStories,
            tooltip: l10n.refreshTooltip, // ✅ مترجم
          ),
        ],
      ),
      body:
          _isLoading
              ? _buildShimmerGrid()
              : _stories.isEmpty
              ? _buildEmptyState(l10n) // ✅ تمرير l10n
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _stories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0)
                      return _buildAddButton(l10n); // ✅ تمرير l10n
                    return _buildStoryCard(
                      _stories[index - 1],
                      l10n,
                    ); // ✅ تمرير l10n
                  },
                ),
              ),
    );
  }

  Widget _buildAddButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _showCreateStoryModal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.newStoryBtn, // ✅ مترجم
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(MerchantStory story, AppLocalizations l10n) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildStoryContent(story),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 8,
          left: 8,
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                '${story.views}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        if (story.mediaType != 'text')
          Positioned(
            bottom: 8,
            right: 8,
            child: Icon(
              story.mediaType == 'video' ? Icons.videocam : Icons.image,
              color: Colors.white.withOpacity(0.8),
              size: 14,
            ),
          ),

        Positioned(
          top: 6,
          left: 6,
          child: GestureDetector(
            onTap: () => _confirmDelete(story.id, l10n), // ✅ تمرير l10n
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryContent(MerchantStory story) {
    if (story.mediaType == 'text') {
      Color bgColor =
          kStoryColors.firstWhere(
            (c) => c['value'] == story.backgroundColor,
            orElse: () => kStoryColors[0],
          )['color'];

      return Container(
        color: bgColor,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Text(
          story.textContent ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: story.mediaUrl ?? '',
        fit: BoxFit.cover,
        placeholder: (c, u) => Container(color: Colors.grey[200]),
        errorWidget:
            (c, u, e) =>
                const Center(child: Icon(Icons.error, color: Colors.grey)),
      );
    }
  }

  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAddButton(l10n), // ✅ تمرير l10n
          const SizedBox(height: 24),
          Icon(Icons.auto_stories, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            l10n.noActiveStoriesMsg, // ✅ مترجم (سابقاً)
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.shareMomentsWithClientsMsg, // ✅ مترجم
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
