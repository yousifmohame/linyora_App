import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:linyora_project/features/models/reels/screens/edit_reel_screen.dart';
import '../models/model_reel.dart';
import '../services/reels_service.dart';
import 'upload_reel_screen.dart'; // Create this screen later for the upload action

class ModelReelsScreen extends StatefulWidget {
  const ModelReelsScreen({Key? key}) : super(key: key);

  @override
  State<ModelReelsScreen> createState() => _ModelReelsScreenState();
}

class _ModelReelsScreenState extends State<ModelReelsScreen> {
  final ReelsService _service = ReelsService();
  List<ModelReel> _reels = [];
  bool _isLoading = true;

  // Colors matching your theme (Rose/Purple)
  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);
  final Color _bgStart = const Color(0xFFFFF1F2); // Rose-50 (approx)
  final Color _bgEnd = const Color(0xFFF3E8FF); // Purple-50 (approx)

  @override
  void initState() {
    super.initState();
    _fetchReels();
  }

  Future<void> _fetchReels() async {
    setState(() => _isLoading = true);
    try {
      final reels = await _service.getMyReels();
      if (mounted) {
        setState(() {
          _reels = reels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل جلب البيانات')));
      }
    }
  }

  Future<void> _deleteReel(int reelId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("حذف الفيديو؟"),
            content: const Text(
              "هل أنت متأكد من حذف هذا الفيديو؟ لا يمكن التراجع عن هذا الإجراء.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("حذف"),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final success = await _service.deleteReel(reelId);
    if (success) {
      setState(() {
        _reels.removeWhere((r) => r.id == reelId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحذف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء الحذف'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _reels.where((r) => r.isActive).length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgStart, _bgEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Header ---
              _buildHeader(),

              // --- Stats & Action Bar ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildBadge(
                          "العدد الكلي: ${_reels.length}",
                          Colors.pink.shade100,
                          Colors.pink.shade800,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          "نشط: $activeCount",
                          Colors.green.shade100,
                          Colors.green.shade800,
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // ✅ ننتظر نتيجة العودة من صفحة الرفع
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UploadReelScreen(),
                          ),
                        );
                        // ✅ بمجرد العودة (سواء تم الرفع أم لا)، نقوم بتحديث القائمة
                        _fetchReels();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("رفع فيديو"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purpleColor, // Your branding color
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // --- Content ---
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _reels.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reels.length,
                          separatorBuilder:
                              (c, i) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildReelCard(_reels[index]);
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "إدارة الريلز",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              foreground:
                  Paint()
                    ..shader = LinearGradient(
                      colors: [_roseColor, _purpleColor],
                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "اعرضي وتتبعي أداء مقاطع الفيديو الخاصة بك",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Icon(
              Icons.video_library_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "لا توجد فيديوهات بعد",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "ابدئي برفع مقاطع الفيديو لعرض منتجاتك",
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildReelCard(ModelReel reel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: reel.thumbnailUrl ?? '',
                  width: 70,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(color: Colors.grey[200]),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        reel.caption.isEmpty ? "بدون عنوان" : reel.caption,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(reel.isActive),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 10,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(reel.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats Row
                Row(
                  children: [
                    _buildStatItem(
                      Icons.remove_red_eye,
                      "${reel.viewsCount}",
                      "مشاهدة",
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      Icons.favorite,
                      "${reel.likesCount}",
                      "إعجاب",
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
            onSelected: (value) async {
              if (value == 'edit') {
                // ✅ الانتقال لصفحة التعديل وانتظار النتيجة
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditReelScreen(reel: reel)),
                );
                // ✅ إذا تم التعديل بنجاح (result == true)، نحدث القائمة
                if (result == true) {
                  _fetchReels();
                }
              } else if (value == 'delete') {
                _deleteReel(reel.id);
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('تعديل'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('حذف', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Text(
        isActive ? "نشط" : "غير نشط",
        style: TextStyle(
          color: isActive ? Colors.green : Colors.orange,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
