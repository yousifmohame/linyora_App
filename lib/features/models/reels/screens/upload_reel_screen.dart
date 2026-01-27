import 'dart:convert'; // ✅ ضروري لـ jsonEncode
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // ✅ أضف هذه المكتبة في pubspec.yaml لتحديد نوع الملف بدقة
import 'package:linyora_project/core/api/api_client.dart';

// --- Models ---
class ProductSelection {
  final int id;
  final String name;
  final String? imageUrl;
  final int? agreementId;
  final String? storeName;

  ProductSelection({
    required this.id,
    required this.name,
    this.imageUrl,
    this.agreementId,
    this.storeName,
  });

  factory ProductSelection.fromJson(
    Map<String, dynamic> json, {
    bool isAgreement = false,
  }) {
    if (isAgreement) {
      return ProductSelection(
        id: json['product_id'],
        name: json['product_name'],
        imageUrl: json['product_image_url'],
        agreementId: json['agreement_id'],
        storeName: json['merchant_store_name'],
      );
    } else {
      String? img;
      if (json['variants'] != null && (json['variants'] as List).isNotEmpty) {
        // التعامل مع اختلاف هيكلية الصور بين المنتجات المختلفة
        var firstImg = json['variants'][0]['images'];
        if (firstImg is List && firstImg.isNotEmpty) {
          img = firstImg[0];
        } else if (firstImg is String) {
          // في حال كانت string JSON
          try {
            List parsed = jsonDecode(firstImg);
            if (parsed.isNotEmpty) img = parsed[0];
          } catch (e) {}
        }
      }
      return ProductSelection(
        id: json['id'],
        name: json['name'],
        imageUrl: img,
      );
    }
  }
}

class UploadReelScreen extends StatefulWidget {
  const UploadReelScreen({Key? key}) : super(key: key);

  @override
  State<UploadReelScreen> createState() => _UploadReelScreenState();
}

class _UploadReelScreenState extends State<UploadReelScreen> {
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();

  File? _selectedVideoFile;
  VideoPlayerController? _videoController;
  final TextEditingController _captionController = TextEditingController();

  List<ProductSelection> _allProducts = [];
  List<ProductSelection> _activeAgreements = [];
  List<ProductSelection> _taggedProducts = [];
  int? _selectedAgreementId;

  bool _isLoadingData = true;
  bool _isUploading = false;

  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final responses = await Future.wait([
        _apiClient.get('/browse/all-products'),
        _apiClient.get('/agreements/active-for-user'),
      ]);

      if (mounted) {
        setState(() {
          _allProducts =
              (responses[0].data as List)
                  .map((e) => ProductSelection.fromJson(e, isAgreement: false))
                  .toList();

          _activeAgreements =
              (responses[1].data as List)
                  .map((e) => ProductSelection.fromJson(e, isAgreement: true))
                  .toList();

          final agreementProductIds =
              _activeAgreements.map((e) => e.id).toSet();
          _allProducts.removeWhere((p) => agreementProductIds.contains(p.id));

          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickVideo() async {
    // التأكد من اختيار فيديو من المعرض
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3), // تقييد المدة (اختياري)
    );

    if (video != null) {
      final file = File(video.path);
      // التحقق من الحجم (مثلاً 100 ميجابايت)
      int sizeInBytes = file.lengthSync();
      double sizeInMb = sizeInBytes / (1024 * 1024);
      if (sizeInMb > 100) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حجم الفيديو يجب أن يكون أقل من 100 ميجابايت'),
            ),
          );
        return;
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      setState(() {
        _selectedVideoFile = file;
        _videoController = controller;
      });
    }
  }

  void _toggleProductTag(ProductSelection product) {
    setState(() {
      if (_taggedProducts.any((p) => p.id == product.id)) {
        _taggedProducts.removeWhere((p) => p.id == product.id);
        if (_selectedAgreementId == product.agreementId) {
          _selectedAgreementId = null;
        }
      } else {
        _taggedProducts.add(product);
        if (product.agreementId != null) {
          _selectedAgreementId = product.agreementId;
          // إذا كنت تريد السماح باتفاقية واحدة فقط لكل فيديو:
          // _taggedProducts.removeWhere((p) => p.id != product.id);
        }
      }
    });
  }

  Future<void> _uploadReel() async {
    if (_selectedVideoFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار فيديو')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String fileName = _selectedVideoFile!.path.split('/').last;

      // تجهيز البيانات
      // ملاحظة: تأكد أنك تستخدم jsonEncode كما شرحنا سابقاً
      String taggedProductsJson = jsonEncode(
        _taggedProducts.map((e) => e.id).toList(),
      );

      FormData formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          _selectedVideoFile!.path,
          filename: fileName,
          contentType: MediaType('video', 'mp4'),
        ),
        'caption': _captionController.text,
        'tagged_products': taggedProductsJson,
        if (_selectedAgreementId != null) 'agreement_id': _selectedAgreementId,
      });

      // 1️⃣ عملية الرفع (تأخذ وقتاً)
      await _apiClient.post('/reels', data: formData);

      // ✅ 2️⃣ التحقق الحاسم: هل الشاشة لا تزال موجودة؟
      if (!mounted) return;

      // إذا وصلنا هنا، فالشاشة موجودة ويمكن استخدام context بأمان
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفع الفيديو بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );

      // العودة للصفحة السابقة مع إرسال نتيجة true
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Upload error: $e");

      // ✅ 3️⃣ التحقق الحاسم داخل الـ catch أيضاً
      if (!mounted) return;

      String errorMessage = 'فشل الرفع، حاول مرة أخرى';

      if (e is DioException) {
        if (e.response?.statusCode == 500) {
          errorMessage = 'خطأ في السيرفر (500). تأكد من تحديث قاعدة البيانات.';
        } else if (e.response?.statusCode == 413) {
          errorMessage = 'حجم الفيديو كبير جداً';
        } else {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
      }

      // الآن آمن للعرض
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      // ✅ 4️⃣ التحقق قبل تحديث الواجهة
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "رفع فيديو جديد",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoadingData
              ? Center(child: CircularProgressIndicator(color: _roseColor))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickVideo,
                      child: Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child:
                            _selectedVideoFile == null
                                ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 48,
                                      color: _roseColor,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "اضغط لاختيار فيديو",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "MP4, MOV (Max 100MB)",
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                                : ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (_videoController != null &&
                                          _videoController!.value.isInitialized)
                                        AspectRatio(
                                          aspectRatio:
                                              _videoController!
                                                  .value
                                                  .aspectRatio,
                                          child: VideoPlayer(_videoController!),
                                        )
                                      else
                                        const CircularProgressIndicator(),
                                      Container(
                                        color: Colors.black26,
                                        child: const Center(
                                          child: Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "الوصف",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "اكتب وصفاً جذاباً للفيديو...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "المنتجات المتاحة",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showProductSelectionSheet(),
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: _purpleColor,
                          ),
                          label: Text(
                            "إضافة منتج",
                            style: TextStyle(color: _purpleColor),
                          ),
                        ),
                      ],
                    ),
                    if (_taggedProducts.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _taggedProducts
                                .map(
                                  (p) => Chip(
                                    label: Text(p.name),
                                    avatar:
                                        p.imageUrl != null
                                            ? CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                p.imageUrl!,
                                              ),
                                            )
                                            : null,
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                    ),
                                    onDeleted: () => _toggleProductTag(p),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                )
                                .toList(),
                      )
                    else
                      const Text(
                        "لم يتم تحديد منتجات",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),

                    if (_selectedAgreementId != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.handshake,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "مرتبط باتفاقية رقم #$_selectedAgreementId",
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _uploadReel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _roseColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isUploading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  "نشر الفيديو",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  void _showProductSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setStateSheet) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "اختر المنتجات",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_activeAgreements.isNotEmpty) ...[
                            Text(
                              "اتفاقياتي النشطة",
                              style: TextStyle(
                                color: _roseColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._activeAgreements.map(
                              (p) => _buildProductCheckbox(p, setStateSheet),
                            ),
                            const SizedBox(height: 20),
                          ],
                          const Text(
                            "جميع المنتجات",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._allProducts.map(
                            (p) => _buildProductCheckbox(p, setStateSheet),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("تم"),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ).then((_) => setState(() {}));
  }

  Widget _buildProductCheckbox(
    ProductSelection product,
    Function setStateSheet,
  ) {
    final bool isSelected = _taggedProducts.any((p) => p.id == product.id);
    return CheckboxListTile(
      value: isSelected,
      onChanged:
          (bool? value) => setStateSheet(() => _toggleProductTag(product)),
      title: Text(product.name, style: const TextStyle(fontSize: 14)),
      subtitle:
          product.storeName != null
              ? Text(
                product.storeName!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
              : null,
      secondary:
          product.imageUrl != null
              ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(product.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
              : const Icon(Icons.image, color: Colors.grey),
      activeColor: _purpleColor,
      contentPadding: EdgeInsets.zero,
    );
  }
}
