import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

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
  String? _uploadingType;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _followersController;
  late TextEditingController _engagementController;

  final Map<String, TextEditingController> _socialControllers = {};

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

      _nameController = TextEditingController(text: data.name);
      _bioController = TextEditingController(text: data.bio);

      int externalFollowers =
          int.tryParse(
            data.stats.followers.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
      int platformFollowers = data.followersCount ?? 0;
      int totalFollowers = externalFollowers + platformFollowers;

      _followersController = TextEditingController(
        text: totalFollowers.toString(),
      );
      _engagementController = TextEditingController(
        text: data.stats.engagement,
      );

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

  // ✅ تمرير l10n
  Future<void> _pickAndUploadImage(String type, AppLocalizations l10n) async {
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
      _showMessage(l10n.imageUploadedSuccessMsg); // ✅ مترجم
    } catch (e) {
      _showMessage(l10n.uploadFailedMsg, isError: true); // ✅ مترجم
    } finally {
      setState(() => _uploadingType = null);
    }
  }

  void _removePortfolioImage(String url) {
    setState(() {
      _profile!.portfolio.remove(url);
    });
  }

  // ✅ تمرير l10n
  Future<void> _saveProfile(AppLocalizations l10n) async {
    if (_profile == null) return;

    setState(() => _isSaving = true);

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
      _showMessage(
        "${l10n.savedSuccessfullyMsg} ✅",
      ); // ✅ مترجم (من الشاشات السابقة)
    } catch (e) {
      _showMessage(
        l10n.saveFailed,
        isError: true,
      ); // ✅ مترجم (من الشاشات السابقة)
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
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
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
                  _buildHeader(l10n), // ✅ تمرير l10n
                  const SizedBox(height: 20),

                  _buildCard(
                    title: l10n.basicInfoTitle, // ✅ مترجم (موجود مسبقاً)
                    icon: Icons.person,
                    children: [
                      InkWell(
                        onTap:
                            () => _pickAndUploadImage(
                              'cover',
                              l10n,
                            ), // ✅ تمرير l10n
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
                                  children: [
                                    const Icon(
                                      Icons.camera_alt,
                                      color: Colors.grey,
                                    ),
                                    Text(
                                      l10n.addCoverPhotoMsg, // ✅ مترجم
                                      style: const TextStyle(
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
                                onTap:
                                    () => _pickAndUploadImage(
                                      'profile',
                                      l10n,
                                    ), // ✅ تمرير l10n
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
                      _buildTextField(
                        l10n.fullNameLabel,
                        _nameController,
                      ), // ✅ مترجم (سابقاً)
                      const SizedBox(height: 12),
                      _buildTextField(
                        l10n.bioLabel,
                        _bioController,
                        maxLines: 3,
                      ), // ✅ مترجم
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildCard(
                    title: l10n.portfolioTitle, // ✅ مترجم
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
                          if (idx == (_profile?.portfolio.length ?? 0)) {
                            return InkWell(
                              onTap:
                                  () => _pickAndUploadImage(
                                    'portfolio',
                                    l10n,
                                  ), // ✅ تمرير l10n
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
                                          children: [
                                            const Icon(
                                              Icons.add_photo_alternate,
                                              color: Colors.pink,
                                            ),
                                            Text(
                                              l10n.addBtn, // ✅ مترجم
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.pink,
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                            );
                          }

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

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCard(
                          title: l10n.autoStatsTitle, // ✅ مترجم
                          icon: Icons.bar_chart,
                          children: [
                            _buildTextField(
                              l10n.totalFollowersLabel, // ✅ مترجم
                              _followersController,
                              icon: Icons.group,
                              readOnly: true,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              l10n.engagementRateLabel, // ✅ مترجم (سابقاً)
                              _engagementController,
                              icon: Icons.bolt,
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildCard(
                    title: l10n.socialLinksTitle, // ✅ مترجم
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

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSaving
                              ? null
                              : () => _saveProfile(l10n), // ✅ تمرير l10n
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
                                  : Text(
                                    l10n.saveChangesBtn, // ✅ مترجم (سابقاً)
                                    style: const TextStyle(
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

  Widget _buildHeader(AppLocalizations l10n) {
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
            Text(
              l10n.editProfileTitle, // ✅ مترجم (سابقاً)
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.updateInfoToAttractClientsMsg, // ✅ مترجم
          style: const TextStyle(color: Colors.grey),
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
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
        filled: true,
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
