import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:linyora_project/core/api/api_client.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

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
        var firstImg = json['variants'][0]['images'];
        if (firstImg is List && firstImg.isNotEmpty) {
          img = firstImg[0];
        } else if (firstImg is String) {
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

  // ✅ تمرير الترجمة
  Future<void> _pickVideo(AppLocalizations l10n) async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );

    if (video != null) {
      final file = File(video.path);
      int sizeInBytes = file.lengthSync();
      double sizeInMb = sizeInBytes / (1024 * 1024);
      if (sizeInMb > 100) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.videoSizeExceeds100MBMsg)), // ✅ مترجم
          );
        }
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
        }
      }
    });
  }

  // ✅ تمرير الترجمة
  Future<void> _uploadReel(AppLocalizations l10n) async {
    if (_selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectVideoMsg)), // ✅ مترجم
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String fileName = _selectedVideoFile!.path.split('/').last;

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

      await _apiClient.post('/reels', data: formData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.videoUploadedSuccessfullyMsg), // ✅ مترجم
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Upload error: $e");

      if (!mounted) return;

      String errorMessage = l10n.uploadFailedTryAgainMsg; // ✅ مترجم

      if (e is DioException) {
        if (e.response?.statusCode == 500) {
          errorMessage = l10n.serverError500Msg; // ✅ مترجم
        } else if (e.response?.statusCode == 413) {
          errorMessage = l10n.videoTooLargeMsg; // ✅ مترجم
        } else {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          l10n.uploadNewVideoTitle, // ✅ مترجم
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
                      onTap: () => _pickVideo(l10n), // ✅ تمرير l10n
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
                                      l10n.tapToSelectVideo, // ✅ مترجم
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.supportedVideoFormats, // ✅ مترجم
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
                    Text(
                      l10n.descriptionLabel, // ✅ مترجم (ترجمناها سابقاً)
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.writeCatchyDescriptionHint, // ✅ مترجم
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
                        Text(
                          l10n.availableProductsTitle, // ✅ مترجم
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          onPressed:
                              () => _showProductSelectionSheet(
                                l10n,
                              ), // ✅ تمرير l10n
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: _purpleColor,
                          ),
                          label: Text(
                            l10n.addProductBtn, // ✅ مترجم
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
                      Text(
                        l10n.noProductsSelectedMsg, // ✅ مترجم
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
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
                                "${l10n.linkedToAgreementPrefix}$_selectedAgreementId", // ✅ مترجم
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
                        onPressed:
                            _isUploading
                                ? null
                                : () => _uploadReel(l10n), // ✅ تمرير l10n
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
                                : Text(
                                  l10n.publishVideoBtn, // ✅ مترجم
                                  style: const TextStyle(
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

  void _showProductSelectionSheet(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: StatefulBuilder(
                builder: (context, setStateSheet) {
                  if (_activeAgreements.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noActiveAgreementsMsg, // ✅ مترجم
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.mustAcceptAgreementFirstMsg, // ✅ مترجم
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(l10n.okBtn), // ✅ مترجم
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        l10n.chooseProductToPromoteTitle, // ✅ مترجم
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.onlyAgreementProductsShownMsg, // ✅ مترجم
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),

                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: _activeAgreements.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final product = _activeAgreements[index];
                            final bool isSelected = _taggedProducts.any(
                              (p) => p.id == product.id,
                            );

                            return InkWell(
                              onTap: () {
                                setStateSheet(() {
                                  _toggleProductTag(product);
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? _purpleColor.withOpacity(0.05)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? _purpleColor
                                            : Colors.grey.shade200,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[100],
                                        image:
                                            product.imageUrl != null
                                                ? DecorationImage(
                                                  image: NetworkImage(
                                                    product.imageUrl!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                                : null,
                                      ),
                                      child:
                                          product.imageUrl == null
                                              ? const Icon(
                                                Icons.image,
                                                color: Colors.grey,
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (product.storeName != null)
                                            Text(
                                              product.storeName!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            isSelected
                                                ? _purpleColor
                                                : Colors.transparent,
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? _purpleColor
                                                  : Colors.grey.shade400,
                                        ),
                                      ),
                                      child:
                                          isSelected
                                              ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10n.confirmSelectionBtn), // ✅ مترجم
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    ).then((_) => setState(() {}));
  }
}
