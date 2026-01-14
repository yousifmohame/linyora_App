import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  String _activeTab =
      'general'; // general, store, social, notifications, privacy, subscription

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

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _service.updateSettings(_settings!);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم حفظ التغييرات ✅")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("فشل الحفظ ❌")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await _service.uploadBanner(File(image.path));
      setState(() => _settings!.storeBannerUrl = url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم رفع البانر ✅")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("فشل الرفع ❌")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: CustomScrollView(
        slivers: [
          // Tabs List
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTabItem('general', "عام", Icons.settings),
                  _buildTabItem('store', "المتجر", Icons.store),
                  _buildTabItem('social', "التواصل", Icons.share),
                  _buildTabItem(
                    'notifications',
                    "الإشعارات",
                    Icons.notifications,
                  ),
                  _buildTabItem('privacy', "الخصوصية", Icons.privacy_tip),
                  _buildTabItem('subscription', "الاشتراك", Icons.diamond),
                ],
              ),
            ),
          ),

          // Content Area
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
                      _buildActiveContent(),
                      const SizedBox(height: 24),
                      if (_activeTab !=
                          'subscription') // لا نظهر زر الحفظ في صفحة الاشتراك
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                (_isSaving || _isUploading)
                                    ? null
                                    : _saveSettings,
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
                                    : const Text(
                                      "حفظ التغييرات",
                                      style: TextStyle(
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

  // --- Widgets ---

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

  Widget _buildActiveContent() {
    switch (_activeTab) {
      case 'general':
        return _buildGeneralTab();
      case 'store':
        return _buildStoreTab();
      case 'social':
        return _buildSocialTab();
      case 'notifications':
        return _buildNotificationsTab();
      case 'privacy':
        return _buildPrivacyTab();
      case 'subscription':
        return _buildSubscriptionTab();
      default:
        return const SizedBox();
    }
  }

  // 1. General Tab
  Widget _buildGeneralTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("الإعدادات العامة", "اللغة والعملة"),
        const SizedBox(height: 20),
        _buildDropdown("اللغة", "العربية"),
        const SizedBox(height: 16),
        _buildDropdown("العملة", "ريال سعودي (SAR)"),
      ],
    );
  }

  // 2. Store Tab
  Widget _buildStoreTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("معلومات المتجر", "تخصيص هوية متجرك"),
        const SizedBox(height: 20),
        _buildTextField(
          "اسم المتجر",
          _settings!.storeName,
          (v) => _settings!.storeName = v,
          icon: Icons.store,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "وصف المتجر",
          _settings!.storeDescription,
          (v) => _settings!.storeDescription = v,
          icon: Icons.description,
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        const Text(
          "بانر المتجر",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _uploadBanner,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey[100],
            ),
            child:
                _settings!.storeBannerUrl != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: _settings!.storeBannerUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 40,
                          color: Colors.blue[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isUploading ? "جاري الرفع..." : "اضغط لرفع الصورة",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  // 3. Social Tab
  Widget _buildSocialTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("روابط التواصل", "حسابات التواصل الاجتماعي"),
        const SizedBox(height: 20),
        _buildTextField(
          "Instagram",
          _settings!.socialLinks.instagram,
          (v) => _settings!.socialLinks.instagram = v,
          icon: Icons.camera_alt,
          color: Colors.pink,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "Twitter (X)",
          _settings!.socialLinks.twitter,
          (v) => _settings!.socialLinks.twitter = v,
          icon: Icons.alternate_email,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "Facebook",
          _settings!.socialLinks.facebook,
          (v) => _settings!.socialLinks.facebook = v,
          icon: Icons.facebook,
          color: Colors.indigo,
        ),
      ],
    );
  }

  // 4. Notifications Tab
  Widget _buildNotificationsTab() {
    return Column(
      children: [
        _buildSwitchTile(
          "البريد الإلكتروني",
          "استلام إشعارات عبر الإيميل",
          _settings!.notifications.email,
          (v) => setState(() => _settings!.notifications.email = v),
          Icons.email,
          Colors.blue,
        ),
        _buildSwitchTile(
          "إشعارات التطبيق",
          "تنبيهات فورية على الجوال",
          _settings!.notifications.push,
          (v) => setState(() => _settings!.notifications.push = v),
          Icons.notifications_active,
          Colors.amber,
        ),
        _buildSwitchTile(
          "رسائل SMS",
          "استلام رسائل نصية",
          _settings!.notifications.sms,
          (v) => setState(() => _settings!.notifications.sms = v),
          Icons.message,
          Colors.green,
        ),
      ],
    );
  }

  // 5. Privacy Tab
  Widget _buildPrivacyTab() {
    return Column(
      children: [
        _buildSwitchTile(
          "إظهار البريد",
          "عرض البريد الإلكتروني في المتجر",
          _settings!.privacy.showEmail,
          (v) => setState(() => _settings!.privacy.showEmail = v),
          Icons.visibility,
          Colors.grey,
        ),
        _buildSwitchTile(
          "إظهار الهاتف",
          "عرض رقم الهاتف للعملاء",
          _settings!.privacy.showPhone,
          (v) => setState(() => _settings!.privacy.showPhone = v),
          Icons.phone,
          Colors.grey,
        ),
      ],
    );
  }

  // 6. Subscription Tab (Special Offer)
  Widget _buildSubscriptionTab() {
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
              const Text(
                "عرض خاص لفترة محدودة!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "استمتع بجميع مزايا الباقة المتقدمة مجانًا. ابدأ البيع، ووسّع نطاق عملك دون أي تكاليف اشتراك.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
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
                child: const Text(
                  "اشتراك مجاني",
                  style: TextStyle(
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
                        const SnackBar(
                          content: Text("تم تفعيل الاشتراك المجاني!"),
                        ),
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.stars, color: Colors.white),
                  label: const Text(
                    "فعّل اشتراكك المجاني الآن",
                    style: TextStyle(
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

  // Helpers
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

  Widget _buildDropdown(String label, String value) {
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
