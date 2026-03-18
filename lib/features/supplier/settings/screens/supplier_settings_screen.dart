import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ 1. استيراد الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import 'package:linyora_project/features/supplier/settings/models/supplier_settings_models.dart';
import 'package:linyora_project/features/supplier/settings/services/supplier_settings_service.dart';

class SupplierSettingsScreen extends StatefulWidget {
  const SupplierSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SupplierSettingsScreen> createState() => _SupplierSettingsScreenState();
}

class _SupplierSettingsScreenState extends State<SupplierSettingsScreen> {
  final SupplierSettingsService _service = SupplierSettingsService();
  final ImagePicker _picker = ImagePicker();

  SettingsData? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  String _activeTab = 'general';

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final data = await _service.getSettings();
      if (mounted)
        setState(() {
          _settings = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ تمرير l10n للسناك بار
  Future<void> _saveSettings(AppLocalizations l10n) async {
    setState(() => _isSaving = true);
    try {
      await _service.updateSettings(_settings!);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.changesSavedSuccessfullyMsg} ✅")),
        ); // ✅ مترجم
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.saveFailedMsg} ❌")),
        ); // ✅ مترجم
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ✅ تمرير l10n للسناك بار
  Future<void> _uploadBanner(AppLocalizations l10n) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await _service.uploadBanner(File(image.path));
      setState(() => _settings!.storeBannerUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${l10n.imageUploadedSuccessMsg} ✅")),
      ); // ✅ مترجم
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${l10n.uploadFailedMsg} ❌")),
      ); // ✅ مترجم
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTabItem(
                    'general',
                    l10n.generalTab,
                    Icons.settings,
                  ), // ✅ مترجم
                  _buildTabItem('store', l10n.storeTab, Icons.store), // ✅ مترجم
                  _buildTabItem(
                    'social',
                    l10n.socialTab,
                    Icons.share,
                  ), // ✅ مترجم
                  _buildTabItem(
                    'notifications',
                    l10n.notificationsTab,
                    Icons.notifications,
                  ), // ✅ مترجم
                  _buildTabItem(
                    'privacy',
                    l10n.privacyTab,
                    Icons.privacy_tip,
                  ), // ✅ مترجم
                  _buildTabItem(
                    'subscription',
                    l10n.subscriptionTab,
                    Icons.diamond,
                  ), // ✅ مترجم
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildActiveContent(l10n), // ✅ تمرير l10n
                      const SizedBox(height: 24),
                      if (_activeTab != 'subscription')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                (_isSaving || _isUploading)
                                    ? null
                                    : () => _saveSettings(l10n), // ✅ تمرير l10n
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ).copyWith(
                              backgroundBuilder:
                                  (ctx, states, child) => Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFF43F5E),
                                          Color(0xFF9333EA),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: child,
                                  ),
                            ),
                            child:
                                _isSaving
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      l10n.saveChangesBtn, // ✅ مترجم
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
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String id, String label, IconData icon) {
    bool isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient:
              isActive
                  ? const LinearGradient(
                    colors: [Color(0xFFF43F5E), Color(0xFF9333EA)],
                  )
                  : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: const Color(0xFFF43F5E).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContent(AppLocalizations l10n) {
    switch (_activeTab) {
      case 'general':
        return _buildGeneralTab(l10n);
      case 'store':
        return _buildStoreTab(l10n);
      case 'social':
        return _buildSocialTab(l10n);
      case 'notifications':
        return _buildNotificationsTab(l10n);
      case 'privacy':
        return _buildPrivacyTab(l10n);
      case 'subscription':
        return _buildSubscriptionTab(l10n);
      default:
        return const SizedBox();
    }
  }

  Widget _buildGeneralTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          l10n.generalSettingsTitle,
          l10n.languageAndCurrencySubtitle,
        ), // ✅ مترجم
        const SizedBox(height: 20),
        _buildDropdown(l10n.languageLabel, "العربية", [
          "العربية",
          "English",
        ]), // ✅ مترجم
        const SizedBox(height: 16),
        _buildDropdown(l10n.currencyLabel, "SAR", ["SAR", "USD"]), // ✅ مترجم
      ],
    );
  }

  Widget _buildStoreTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          l10n.storeInfoTitle,
          l10n.customizeStoreIdentitySubtitle,
        ), // ✅ مترجم
        const SizedBox(height: 20),
        _buildTextField(
          l10n.storeNameLabel,
          _settings!.storeName,
          (v) => _settings!.storeName = v,
          icon: Icons.store,
        ), // ✅ مترجم
        const SizedBox(height: 16),
        _buildTextField(
          l10n.storeDescriptionLabel,
          _settings!.storeDescription,
          (v) => _settings!.storeDescription = v,
          icon: Icons.description,
          maxLines: 3,
        ), // ✅ مترجم
        const SizedBox(height: 20),

        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l10n.storeBannerTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ), // ✅ مترجم
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _uploadBanner(l10n), // ✅ تمرير l10n
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              image:
                  _settings!.storeBannerUrl != null
                      ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          _settings!.storeBannerUrl!,
                        ),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                _isUploading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.purple[400],
                      ),
                    )
                    : (_settings!.storeBannerUrl == null
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              color: Colors.blue[300],
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.tapToUploadBannerMsg,
                              style: TextStyle(color: Colors.grey[600]),
                            ), // ✅ مترجم
                          ],
                        )
                        : null),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          l10n.socialMediaLinksTitle,
          l10n.socialMediaLinksSubtitle,
        ), // ✅ مترجم
        const SizedBox(height: 20),
        _buildTextField(
          "Instagram",
          _settings!.socialLinks.instagram ?? '',
          (v) => _settings!.socialLinks.instagram = v,
          icon: Icons.camera_alt,
          color: Colors.pink,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "Twitter (X)",
          _settings!.socialLinks.twitter ?? '',
          (v) => _settings!.socialLinks.twitter = v,
          icon: Icons.alternate_email,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "Facebook",
          _settings!.socialLinks.facebook ?? '',
          (v) => _settings!.socialLinks.facebook = v,
          icon: Icons.facebook,
          color: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildNotificationsTab(AppLocalizations l10n) {
    return Column(
      children: [
        _buildSwitchTile(
          l10n.emailNotificationsLabel,
          l10n.receiveEmailNotificationsSubtitle,
          _settings!.notifications.email,
          (v) => setState(() => _settings!.notifications.email = v),
          Icons.email,
          Colors.blue,
        ), // ✅ مترجم
        _buildSwitchTile(
          l10n.appNotificationsLabel,
          l10n.appNotificationsSubtitle,
          _settings!.notifications.push,
          (v) => setState(() => _settings!.notifications.push = v),
          Icons.notifications_active,
          Colors.amber,
        ), // ✅ مترجم
        _buildSwitchTile(
          l10n.smsMessagesLabel,
          l10n.smsNotificationsSubtitle,
          _settings!.notifications.sms,
          (v) => setState(() => _settings!.notifications.sms = v),
          Icons.message,
          Colors.green,
        ), // ✅ مترجم
      ],
    );
  }

  Widget _buildPrivacyTab(AppLocalizations l10n) {
    return Column(
      children: [
        _buildSwitchTile(
          l10n.showEmailLabel,
          l10n.showEmailSubtitle,
          _settings!.privacy.showEmail,
          (v) => setState(() => _settings!.privacy.showEmail = v),
          Icons.visibility,
          Colors.grey,
        ), // ✅ مترجم
        const Divider(),
        _buildSwitchTile(
          l10n.showPhoneLabel,
          l10n.showPhoneSubtitle,
          _settings!.privacy.showPhone,
          (v) => setState(() => _settings!.privacy.showPhone = v),
          Icons.phone,
          Colors.grey,
        ), // ✅ مترجم
      ],
    );
  }

  Widget _buildSubscriptionTab(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.diamond, size: 32, color: Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.specialOfferTitle, // ✅ مترجم
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.specialOfferDesc, // ✅ مترجم
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.freeSubscriptionLabel, // ✅ مترجم
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.freeSubscriptionActivatedMsg),
                        ),
                      ), // ✅ مترجم
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.stars, color: Colors.white),
                  label: Text(
                    l10n.activateFreeSubscriptionBtn, // ✅ مترجم
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    IconData? icon,
    Color? color,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            icon != null ? Icon(icon, color: color ?? Colors.blue) : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        activeColor: color,
      ),
    );
  }
}
