import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import '../../../models/story_model.dart';
import '../services/stories_service.dart';

class StoryViewerScreen extends StatefulWidget {
  final int feedId;        // user_id أو section_id
  final String title;      // اسم المستخدم أو القسم
  final String imageUrl;   // الصورة
  final bool isSection;    // لتحديد نوع الطلب

  const StoryViewerScreen({
    super.key,
    required this.feedId,
    required this.title,
    required this.imageUrl,
    required this.isSection,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final StoryController controller = StoryController();
  final StoriesService _storiesService = StoriesService();
  
  List<StoryModel>? _stories; // القصص المحملة
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    final stories = await _storiesService.getStoriesById(widget.feedId, widget.isSection);
    if (mounted) {
      setState(() {
        if (stories.isNotEmpty) {
          _stories = stories;
        } else {
          _hasError = true; // لا يوجد قصص أو حدث خطأ
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("لا توجد قصص لعرضها", style: TextStyle(color: Colors.white)),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("رجوع"))
            ],
          ),
        ),
      );
    }

    if (_stories == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // تحويل القصص إلى StoryItem
    final List<StoryItem> storyItems = _stories!.map((story) {
      if (story.mediaType == MediaType.video) {
        return StoryItem.pageVideo(
          story.mediaUrl,
          controller: controller,
          caption: story.textContent != null 
              ? Text(story.textContent!, style: const TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black45)) 
              : null,
          shown: story.isViewed,
        );
      } else {
        return StoryItem.pageImage(
          url: story.mediaUrl,
          controller: controller,
          caption: story.textContent != null 
              ? Text(story.textContent!, style: const TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black45)) 
              : null,
          shown: story.isViewed,
        );
      }
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          StoryView(
            storyItems: storyItems,
            controller: controller,
            onStoryShow: (storyItem, index) {
              _storiesService.markAsViewed(_stories![index].id);
            },
            onComplete: () => Navigator.pop(context),
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) Navigator.pop(context);
            },
          ),
          
          // Header (معلومات المستخدم)
          Positioned(
            top: 50,
            right: 20,
            left: 20,
            child: Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(widget.imageUrl), radius: 20),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}