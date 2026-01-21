import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/models/stories/models/story_model.dart';
import 'package:linyora_project/features/models/stories/screens/create_story_sheet.dart';
import 'package:linyora_project/features/models/stories/services/stories_service.dart';

class InfluencerStoriesScreen extends StatefulWidget {
  const InfluencerStoriesScreen({Key? key}) : super(key: key);

  @override
  State<InfluencerStoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<InfluencerStoriesScreen> {
  final StoriesService _service = StoriesService();
  List<StoryModel> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    try {
      final data = await _service.getMyStories();
      if (mounted)
        setState(() {
          _stories = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStory(int id) async {
    try {
      await _service.deleteStory(id);
      _fetchStories(); // تحديث
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم الحذف")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("فشل الحذف")));
    }
  }

  void _showCreateSheet() async {
    // نفتح BottomSheet وننتظر النتيجة
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // للسماح بارتفاع كامل
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateStorySheet(),
    );

    if (result == true) {
      _fetchStories(); // تحديث القائمة إذا تم النشر
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: const Color(0xFFF105C6),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text("قصة جديدة"),
      ),
      body: Stack(
        children: [
          // الخلفية
          Positioned(
            top: -50,
            right: -50,
            child: _blurCircle(Colors.blue.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _blurCircle(Colors.purple.withOpacity(0.15)),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text(
                  "القصص النشطة",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                iconTheme: const IconThemeData(color: Colors.black),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_stories.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "لا توجد قصص نشطة حالياً",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStoryCard(_stories[index]),
                    childCount: _stories.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(StoryModel story) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Preview
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                color:
                    story.type == 'text'
                        ? Color(
                          int.parse(
                            (story.backgroundColor ?? '#000000').replaceAll(
                              '#',
                              '0xFF',
                            ),
                          ),
                        )
                        : Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    story.type == 'text'
                        ? Center(
                          child: Text(
                            story.textContent ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        )
                        : (story.mediaUrl != null
                            ? CachedNetworkImage(
                              imageUrl: story.mediaUrl!,
                              fit: BoxFit.cover,
                            )
                            : const Icon(Icons.image)),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeBadge(story.type),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.remove_red_eye,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${story.views}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat(
                          'h:mm a',
                        ).format(DateTime.parse(story.createdAt)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete
            IconButton(
              onPressed: () => _confirmDelete(story.id),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color =
        type == 'image'
            ? Colors.blue
            : (type == 'video' ? Colors.purple : Colors.green);
    IconData icon =
        type == 'image'
            ? Icons.image
            : (type == 'video' ? Icons.videocam : Icons.text_fields);
    String label =
        type == 'image' ? 'صورة' : (type == 'video' ? 'فيديو' : 'نص');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("حذف القصة"),
            content: const Text("هل أنت متأكد؟ سيتم حذف القصة نهائياً."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteStory(id);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("حذف"),
              ),
            ],
          ),
    );
  }

  Widget _blurCircle(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
