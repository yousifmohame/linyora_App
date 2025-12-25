import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/stories/screens/story_viewer_screen.dart';
import '../services/stories_service.dart';
import '../../../models/story_feed_item.dart';

class StoriesSection extends StatefulWidget {
  const StoriesSection({super.key});

  @override
  State<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends State<StoriesSection> {
  final StoriesService _storiesService = StoriesService();
  List<StoryFeedItem> _feedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    final items = await _storiesService.getStoriesFeed();
    if (mounted) {
      setState(() {
        _feedItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    if (_feedItems.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 90,
      margin: const EdgeInsets.only(top: 5, bottom: 0),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _feedItems.length + 1, // +1 لزر "قصتي"
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) return _buildAddStoryItem(); // زر قصتي

          final item = _feedItems[index - 1];
          return _buildFeedItem(item);
        },
      ),
    );
  }

  Widget _buildAddStoryItem() {
    return Column(children: []);
  }

  Widget _buildFeedItem(StoryFeedItem item) {
    return GestureDetector(
      onTap: () {
        // فتح العارض وتمرير الـ ID والنوع
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => StoryViewerScreen(
                  feedId: item.id,
                  title: item.title,
                  imageUrl: item.imageUrl,
                  isSection: item.isAdminSection, // هنا نحدد النوع
                ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              // الشكل: دائرة للمستخدمين، ومستطيل بحواف دائرية للأقسام
              shape: item.isAdminSection ? BoxShape.rectangle : BoxShape.circle,
              borderRadius:
                  item.isAdminSection ? BorderRadius.circular(15) : null,

              // لون الإطار: رمادي إذا شوهد، ملون إذا جديد
              border:
                  !item.allViewed
                      ? Border.all(color: Colors.purple, width: 2.5)
                      : Border.all(color: Colors.grey, width: 1.5),
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape:
                    item.isAdminSection ? BoxShape.rectangle : BoxShape.circle,
                borderRadius:
                    item.isAdminSection ? BorderRadius.circular(12) : null,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(item.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: 70,
            child: Text(
              item.title,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
