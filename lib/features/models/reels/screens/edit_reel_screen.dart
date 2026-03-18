import 'package:flutter/material.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import 'package:linyora_project/features/models/reels/models/model_reel.dart';
import '../services/reels_service.dart';

class EditReelScreen extends StatefulWidget {
  final ModelReel reel;

  const EditReelScreen({Key? key, required this.reel}) : super(key: key);

  @override
  State<EditReelScreen> createState() => _EditReelScreenState();
}

class _EditReelScreenState extends State<EditReelScreen> {
  final ReelsService _service = ReelsService();
  late TextEditingController _captionController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.reel.caption);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ✅ تمرير l10n لترجمة رسائل السناك بار
  Future<void> _handleUpdate(AppLocalizations l10n) async {
    setState(() => _isUpdating = true);

    final success = await _service.updateReel(
      widget.reel.id,
      _captionController.text,
    );

    setState(() => _isUpdating = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.videoUpdatedSuccessMsg),
            backgroundColor: Colors.green,
          ), // ✅ مترجم
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.updateFailedMsg),
            backgroundColor: Colors.red,
          ), // ✅ مترجم
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.editVideoTitle,
          style: const TextStyle(color: Colors.black),
        ), // ✅ مترجم
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.descriptionLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ), // ✅ مترجم
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: l10n.writeNewDescriptionHint, // ✅ مترجم
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    _isUpdating
                        ? null
                        : () => _handleUpdate(l10n), // ✅ تمرير l10n
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isUpdating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          l10n.saveChangesBtn, // ✅ مترجم (ترجمناها في شاشة سابقة)
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
