import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/reels/services/reels_service.dart';

// ✅ 1. استيراد ملف الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../../../../models/comment_model.dart';

class CommentsSheet extends StatefulWidget {
  final String reelId;
  final ReelsService service;
  final VoidCallback onCommentAdded;

  const CommentsSheet({
    Key? key,
    required this.reelId,
    required this.service,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await widget.service.getComments(widget.reelId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error loading comments: $e");
    }
  }

  Future<void> _addComment(AppLocalizations l10n) async {
    if (_controller.text.trim().isEmpty) return;

    final text = _controller.text;
    _controller.clear();
    FocusScope.of(context).unfocus();

    try {
      final newComment = await widget.service.addComment(widget.reelId, text);
      setState(() {
        _comments.insert(0, newComment);
      });
      widget.onCommentAdded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToSendCommentMsg)), // ✅ مترجم
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, color: Colors.grey[300]),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.commentsTitle, // ✅ مترجم
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _comments.isEmpty
                      ? Center(
                        child: Text(
                          l10n.noCommentsYetMsg, // ✅ مترجم
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  (comment.userAvatar.isNotEmpty)
                                      ? CachedNetworkImageProvider(
                                        comment.userAvatar,
                                      )
                                      : null,
                              child:
                                  (comment.userAvatar.isEmpty)
                                      ? const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                      )
                                      : null,
                            ),
                            title: Text(
                              comment.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              comment.content,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        },
                      ),
            ),
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                left: 10,
                right: 10,
                top: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: l10n.addCommentHint, // ✅ مترجم
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _addComment(l10n), // ✅ تمرير الترجمة
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
