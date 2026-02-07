import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linyora_project/features/models/profile/models/profile_model.dart';
import '../services/profile_service.dart';

class InfluencerProfileSettingsScreen extends StatefulWidget {
  const InfluencerProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<InfluencerProfileSettingsScreen> createState() =>
      _ModelProfileSettingsScreenState();
}

class _ModelProfileSettingsScreenState
    extends State<InfluencerProfileSettingsScreen> {
  final ProfileService _service = ProfileService();
  final ImagePicker _picker = ImagePicker();

  ProfileData? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _uploadingType; // 'profile', 'cover', 'portfolio'

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _followersController;
  late TextEditingController _engagementController;

  // Social Controllers
  final Map<String, TextEditingController> _socialControllers = {};

  // Colors
  final Color _roseColor = const Color(0xFFE11D48);
  final Color _purpleColor = const Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getProfile();
      _profile = data as ProfileData?;

      // Initialize Controllers
      _nameController = TextEditingController(text: data.name);
      _bioController = TextEditingController(text: data.bio);

      // ✅✅ منطق حساب المتابعين (الحالي + المنصة)
      // 1. تحويل المتابعين الخارجيين (المسجلين يدوياً) إلى رقم (مع إزالة أي نصوص مثل k أو ,)
      int externalFollowers =
          int.tryParse(
            data.stats.followers.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;

      // 2. جلب متابعي المنصة (افترضنا أن المتغير اسمه followersCount في الموديل، عدله حسب الموديل لديك)
      // إذا لم يكن موجوداً في الموديل، يجب إضافته في ProfileData
      int platformFollowers = data.followersCount ?? 0;

      // 3. الجمع والعرض
      int totalFollowers = externalFollowers + platformFollowers;
      _followersController = TextEditingController(
        text: totalFollowers.toString(),
      );

      // الإحصائيات الأخرى كما هي
      _engagementController = TextEditingController(
        text: data.stats.engagement,
      );

      // Socials
      _socialControllers['instagram'] = TextEditingController(
        text: data.socialLinks.instagram,
      );
      _socialControllers['twitter'] = TextEditingController(
        text: data.socialLinks.twitter,
      );
      _socialControllers['facebook'] = TextEditingController(
        text: data.socialLinks.facebook,
      );
      _socialControllers['tiktok'] = TextEditingController(
        text: data.socialLinks.tiktok,
      );
      _socialControllers['snapchat'] = TextEditingController(
        text: data.socialLinks.snapchat,
      );
      _socialControllers['whatsapp'] = TextEditingController(
        text: data.socialLinks.whatsapp,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _uploadingType = type);

    try {
      final url = await _service.uploadImage(File(image.path));
      setState(() {
        if (type == 'profile')
          _profile!.profilePictureUrl = url;
        else if (type == 'cover')
          _profile!.storeBannerUrl = url;
        else if (type == 'portfolio')
          _profile!.portfolio.add(url);
      });
      _showMessage("تم رفع الصورة بنجاح");
    } catch (e) {
      _showMessage("فشل الرفع", isError: true);
    } finally {
      setState(() => _uploadingType = null);
    }
  }

  void _removePortfolioImage(String url) {
    setState(() {
      _profile!.portfolio.remove(url);
    });
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;

    setState(() => _isSaving = true);

    // Update model from controllers
    _profile!.name = _nameController.text;
    _profile!.bio = _bioController.text;
    _profile!.socialLinks.instagram = _socialControllers['instagram']!.text;
    _profile!.socialLinks.twitter = _socialControllers['twitter']!.text;
    _profile!.socialLinks.facebook = _socialControllers['facebook']!.text;
    _profile!.socialLinks.tiktok = _socialControllers['tiktok']!.text;
    _profile!.socialLinks.snapchat = _socialControllers['snapchat']!.text;
    _profile!.socialLinks.whatsapp = _socialControllers['whatsapp']!.text;

    try {
      await _service.updateProfile(_profile! as ProfileData);
      _showMessage("تم حفظ التغييرات بنجاح ✅");
    } catch (e) {
      _showMessage("فشل الحفظ", isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.shade50.withOpacity(0.3),
                  Colors.purple.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: _buildBlurBlob(Colors.pink.shade200),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurBlob(Colors.purple.shade200),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // 1. Basic Info Card
                  _buildCard(
                    title: "المعلومات الأساسية",
                    icon: Icons.person,
                    children: [
                      // Cover Photo
                      InkWell(
                        onTap: () => _pickAndUploadImage('cover'),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            image:
                                _profile?.storeBannerUrl != null
                                    ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        _profile!.storeBannerUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_profile?.storeBannerUrl == null)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.camera_alt, color: Colors.grey),
                                    Text(
                                      "أضف صورة غلاف",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              if (_uploadingType == 'cover')
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Profile Pic
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  _profile?.profilePictureUrl != null
                                      ? CachedNetworkImageProvider(
                                        _profile!.profilePictureUrl!,
                                      )
                                      : null,
                              child:
                                  _profile?.profilePictureUrl == null
                                      ? Text(
                                        _profile?.name[0] ?? 'U',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: _roseColor,
                                        ),
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () => _pickAndUploadImage('profile'),
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.white,
                                  child:
                                      _uploadingType == 'profile'
                                          ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Icon(
                                            Icons.camera_alt,
                                            size: 16,
                                            color: _roseColor,
                                          ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      _buildTextField("الاسم الكامل", _nameController),
                      const SizedBox(height: 12),
                      _buildTextField(
                        "النبذة التعريفية (Bio)",
                        _bioController,
                        maxLines: 3,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Portfolio Card
                  _buildCard(
                    title: "معرض الأعمال",
                    icon: Icons.image,
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: (_profile?.portfolio.length ?? 0) + 1,
                        itemBuilder: (ctx, idx) {
                          // زر الإضافة في النهاية
                          if (idx == (_profile?.portfolio.length ?? 0)) {
                            return InkWell(
                              onTap: () => _pickAndUploadImage('portfolio'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.pink.shade200,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child:
                                    _uploadingType == 'portfolio'
                                        ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                        : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              color: Colors.pink,
                                            ),
                                            Text(
                                              "إضافة",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.pink,
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                            );
                          }

                          // الصور الموجودة
                          final imgUrl = _profile!.portfolio[idx];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: imgUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () => _removePortfolioImage(imgUrl),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.red,
                                    child: Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. Stats & Socials
                  // داخل دالة build، قسم الإحصائيات:
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCard(
                          title:
                              "الإحصائيات (تلقائي)", // تغيير العنوان ليوضح أنها تلقائية
                          icon: Icons.bar_chart,
                          children: [
                            _buildTextField(
                              "إجمالي المتابعين (خارجي + منصة)",
                              _followersController,
                              icon: Icons.group,
                              readOnly: true, // ✅ ممنوع التعديل
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              "التفاعل",
                              _engagementController,
                              icon: Icons.bolt,
                              readOnly: true, // ✅ ممنوع التعديل
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildCard(
                    title: "روابط التواصل",
                    icon: Icons.link,
                    children: [
                      _buildSocialInput(
                        "Instagram",
                        _socialControllers['instagram']!,
                        Colors.purple,
                      ),
                      _buildSocialInput(
                        "Twitter",
                        _socialControllers['twitter']!,
                        Colors.blue,
                      ),
                      _buildSocialInput(
                        "TikTok",
                        _socialControllers['tiktok']!,
                        Colors.black,
                      ),
                      _buildSocialInput(
                        "Snapchat",
                        _socialControllers['snapchat']!,
                        Colors.amber,
                      ),
                      _buildSocialInput(
                        "Facebook",
                        _socialControllers['facebook']!,
                        Colors.indigo,
                      ),
                      _buildSocialInput(
                        "WhatsApp",
                        _socialControllers['whatsapp']!,
                        Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      icon:
                          _isSaving
                              ? const SizedBox()
                              : const Icon(Icons.save, color: Colors.white),
                      label: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_roseColor, _purpleColor],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child:
                              _isSaving
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    "حفظ التغييرات",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person, color: _roseColor, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              "تعديل الملف الشخصي",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "قم بتحديث معلوماتك لجذب المزيد من العملاء",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_roseColor, _purpleColor]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    IconData? icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly, // ✅ تفعيل القراءة فقط
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            icon != null
                ? Icon(
                  icon,
                  size: 18,
                  color: readOnly ? Colors.grey : Colors.grey,
                )
                : null,
        filled: true,
        // ✅ تغيير لون الخلفية إذا كان للقراءة فقط لتمييزه
        fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _purpleColor),
        ),
      ),
    );
  }

  Widget _buildSocialInput(
    String label,
    TextEditingController controller,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.link, color: color, size: 18),
          filled: true,
          fillColor: Colors.grey[50],
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
