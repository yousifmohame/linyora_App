import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

// ✅ 1. استيراد ملف الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import 'package:linyora_project/features/models/reels/screens/edit_reel_screen.dart';
import '../models/model_reel.dart';
import '../services/reels_service.dart';
import 'upload_reel_screen.dart';

class ModelReelsScreen extends StatefulWidget {
  const ModelReelsScreen({Key? key}) : super(key: key);

  @override
  State<ModelReelsScreen> createState() => _ModelReelsScreenState();
}

class _ModelReelsScreenState extends State<ModelReelsScreen> {
  final ReelsService _service = ReelsService();
  List<ModelReel> _reels = [];
  bool _isLoading = true;

  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);
  final Color _bgStart = const Color(0xFFFFF1F2);
  final Color _bgEnd = const Color(0xFFF3E8FF);

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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToFetchDataMsg)),
        ); // ✅ مترجم
      }
    }
  }

  Future<void> _deleteReel(int reelId, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.deleteVideoTitle), // ✅ مترجم
            content: Text(l10n.deleteVideoConfirmMsg), // ✅ مترجم
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancelBtn), // ✅ مترجم
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete), // ✅ مترجم
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
          SnackBar(
            content: Text(l10n.deletedSuccessfullyMsg), // ✅ مترجم
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDeletingMsg), // ✅ مترجم
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
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;
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
              _buildHeader(l10n), // ✅ تمرير l10n

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
                          "${l10n.totalCountLabel}${_reels.length}", // ✅ مترجم
                          Colors.pink.shade100,
                          Colors.pink.shade800,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          "${l10n.activeCountLabel}$activeCount", // ✅ مترجم
                          Colors.green.shade100,
                          Colors.green.shade800,
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UploadReelScreen(),
                          ),
                        );
                        _fetchReels();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.uploadVideoBtn), // ✅ مترجم
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purpleColor,
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

              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _reels.isEmpty
                        ? _buildEmptyState(l10n) // ✅ تمرير l10n
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reels.length,
                          separatorBuilder:
                              (c, i) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildReelCard(
                              _reels[index],
                              l10n,
                            ); // ✅ تمرير l10n
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            l10n.reelsManagementTitle, // ✅ مترجم
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
            l10n.reelsManagementSubtitle, // ✅ مترجم
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

  Widget _buildEmptyState(AppLocalizations l10n) {
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
          Text(
            l10n.noVideosYetMsg, // ✅ مترجم
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.startUploadingVideosMsg, // ✅ مترجم
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildReelCard(ModelReel reel, AppLocalizations l10n) {
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

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        reel.caption.isEmpty
                            ? l10n.noTitleMsg
                            : reel.caption, // ✅ مترجم
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(reel.isActive, l10n), // ✅ تمرير l10n
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

                Row(
                  children: [
                    _buildStatItem(
                      Icons.remove_red_eye,
                      "${reel.viewsCount}",
                      l10n.viewsCountLabel,
                    ), // ✅ مترجم
                    const SizedBox(width: 16),
                    _buildStatItem(
                      Icons.favorite,
                      "${reel.likesCount}",
                      l10n.likesCountLabel,
                    ), // ✅ مترجم
                  ],
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditReelScreen(reel: reel)),
                );
                if (result == true) {
                  _fetchReels();
                }
              } else if (value == 'delete') {
                _deleteReel(reel.id, l10n); // ✅ تمرير l10n
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.editBtn), // ✅ مترجم (ترجمناها سابقاً)
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          l10n.delete,
                          style: const TextStyle(color: Colors.red),
                        ), // ✅ مترجم
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, AppLocalizations l10n) {
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
        isActive ? l10n.activeStatus : l10n.inactiveStatus, // ✅ مترجم
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
