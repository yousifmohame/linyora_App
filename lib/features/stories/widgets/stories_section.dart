import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_feedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ 1. حساب النسبة ديناميكياً
    final double screenWidth = MediaQuery.of(context).size.width;

    // عرض عنصر القصة التقريبي (الدائرة + الهوامش)
    // الدائرة حوالي 75px + هوامش = نعتبرها 85px
    const double storyItemWidth = 85.0;

    // حساب الكسر: حجم العنصر / عرض الشاشة
    double fraction = storyItemWidth / screenWidth;

    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 10, bottom: 5),
      child: CarouselSlider.builder(
        itemCount: _feedItems.length,
        itemBuilder: (context, index, realIndex) {
          final item = _feedItems[index];
          return _buildFeedItem(item);
        },
        options: CarouselOptions(
          height: 100,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(seconds: 2),
          autoPlayCurve: Curves.fastLinearToSlowEaseIn,

          // ✅ 2. استخدام النسبة المحسوبة
          // في الموبايل ستكون حوالي 0.21
          // في التابلت ستكون حوالي 0.10 (فتعرض قصص أكثر بجانب بعضها)
          viewportFraction: fraction,

          enableInfiniteScroll: true,
          padEnds: false, // لتبدأ القصص من اليمين/اليسار مباشرة
          scrollDirection: Axis.horizontal,
          pauseAutoPlayOnTouch: true,
        ),
      ),
    );
  }

  // --- عنصر القصة (Feed Item) ---
  Widget _buildFeedItem(StoryFeedItem item) {
    final bool isUnseen = !item.allViewed;

    final Gradient borderGradient =
        isUnseen
            ? const LinearGradient(
              colors: [Color(0xFFF9CE34), Color(0xFFEE2A7B), Color(0xFF6228D7)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            )
            : const LinearGradient(colors: [Colors.grey]);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => StoryViewerScreen(
                  feedId: item.id,
                  title: item.title,
                  imageUrl: item.imageUrl,
                  isSection: item.isAdminSection,
                ),
          ),
        );
        _fetchFeed();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: item.isAdminSection ? BoxShape.rectangle : BoxShape.circle,
              borderRadius:
                  item.isAdminSection ? BorderRadius.circular(22) : null,
              gradient: isUnseen ? borderGradient : null,
              color: isUnseen ? null : Colors.grey[300],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape:
                    item.isAdminSection ? BoxShape.rectangle : BoxShape.circle,
                borderRadius:
                    item.isAdminSection ? BorderRadius.circular(19) : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape:
                      item.isAdminSection
                          ? BoxShape.rectangle
                          : BoxShape.circle,
                  borderRadius:
                      item.isAdminSection ? BorderRadius.circular(17) : null,
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isUnseen ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
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
