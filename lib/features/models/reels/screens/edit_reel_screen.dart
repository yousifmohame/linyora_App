import 'package:flutter/material.dart';
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

  Future<void> _handleUpdate() async {
    setState(() => _isUpdating = true);
    
    final success = await _service.updateReel(widget.reel.id, _captionController.text);
    
    setState(() => _isUpdating = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الفيديو بنجاح'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // ✅ نعود مع قيمة true لإخبار الصفحة السابقة بالتحديث
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل التحديث'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تعديل الفيديو", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("الوصف", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: "أكتب وصفاً جديداً...",
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA), // Purple
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUpdating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("حفظ التغييرات", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}