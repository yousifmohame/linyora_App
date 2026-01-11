import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/merchant_settings_model.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final SettingsService _service = SettingsService();

  // State
  SettingsData? _settings;
  SubscriptionData? _subscription;
  List<SubscriptionData> _history = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingProfile = false;
  bool _isUploadingBanner = false;

  // Tabs
  late TabController _tabController;
  final List<String> _tabs = [
    "عام",
    "المتجر",
    "اجتماعي",
    "تنبيهات",
    "خصوصية",
    "الاشتراك",
  ];

  // Colors
  final Color rose500 = const Color(0xFFF43F5E);
  final Color purple600 = const Color(0xFF9333EA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchData();
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return "";
    try {
      // تحويل النص إلى تاريخ ثم تنسيقه
      DateTime date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date); // النتيجة ستكون: 2026-01-09
    } catch (e) {
      // في حالة الفشل، نرجع النص كما هو ولكن نأخذ أول 10 حروف فقط
      return dateString.length > 10 ? dateString.substring(0, 10) : dateString;
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _service.getSettings();
      final sub = await _service.getSubscriptionStatus();
      final history = await _service.getSubscriptionHistory();

      if (mounted) {
        setState(() {
          _settings = settings;
          _subscription = sub;
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("فشل تحميل البيانات")));
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await _service.updateSettings(_settings!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم حفظ التغييرات بنجاح"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("حدث خطأ أثناء الحفظ"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleImageUpload(String type) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      if (type == 'profile')
        _isUploadingProfile = true;
      else
        _isUploadingBanner = true;
    });

    try {
      final url = await _service.uploadImage(File(picked.path));
      if (url != null) {
        setState(() {
          if (type == 'profile')
            _settings!.profilePictureUrl = url;
          else
            _settings!.storeBannerUrl = url;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم رفع الصورة بنجاح")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("فشل رفع الصورة")));
    } finally {
      setState(() {
        if (type == 'profile')
          _isUploadingProfile = false;
        else
          _isUploadingBanner = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    // Show confirmation dialog first
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (c) => AlertDialog(
                title: const Text("تأكيد الإلغاء"),
                content: const Text("هل أنت متأكد من رغبتك في إلغاء الاشتراك؟"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text("تراجع"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text(
                      "تأكيد",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      try {
        await _service.cancelSubscription();
        _fetchData(); // Refresh data
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم إلغاء الاشتراك")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("فشل إلغاء الاشتراك")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate-50
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom:
            _isLoading
                ? null
                : TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: rose500,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: rose500,
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: rose500))
              : Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGeneralTab(),
                        _buildStoreTab(),
                        _buildSocialTab(),
                        _buildNotificationsTab(),
                        _buildPrivacyTab(),
                        _buildSubscriptionTab(),
                      ],
                    ),
                  ),
                  _buildSaveButton(),
                ],
              ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: rose500,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  // --- Tabs Content ---

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: "الإعدادات العامة",
            icon: Icons.settings,
            child: Column(
              children: [
                _buildDropdown("اللغة", "العربية", ["العربية", "English"]),
                const SizedBox(height: 16),
                _buildDropdown("العملة", "SAR", ["SAR", "USD"]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: "تفاصيل المتجر",
            icon: Icons.store,
            child: Column(
              children: [
                _buildTextField(
                  "اسم المتجر",
                  _settings!.storeName,
                  (v) => _settings!.storeName = v,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  "وصف المتجر",
                  _settings!.storeDescription,
                  (v) => _settings!.storeDescription = v,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Profile Picture
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              _settings!.profilePictureUrl != null
                                  ? CachedNetworkImageProvider(
                                    _settings!.profilePictureUrl!,
                                  )
                                  : null,
                          backgroundColor: Colors.grey.shade200,
                          child:
                              _settings!.profilePictureUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                        if (_isUploadingProfile)
                          const Positioned.fill(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _handleImageUpload('profile'),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: rose500,
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text("صورة المتجر (الشعار). يفضل أن تكون مربعة."),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Banner
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "بنر المتجر",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _handleImageUpload('banner'),
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
                        _isUploadingBanner
                            ? Center(
                              child: CircularProgressIndicator(color: rose500),
                            )
                            : (_settings!.storeBannerUrl == null
                                ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload,
                                      color: rose500,
                                      size: 40,
                                    ),
                                    const Text("اضغط لرفع البنر"),
                                  ],
                                )
                                : null),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildCard(
        title: "روابط التواصل الاجتماعي",
        icon: Icons.share,
        child: Column(
          children: [
            _buildTextField(
              "Instagram",
              _settings!.socialLinks.instagram ?? '',
              (v) => _settings!.socialLinks.instagram = v,
              icon: FontAwesomeIcons.instagram,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              "Twitter (X)",
              _settings!.socialLinks.twitter ?? '',
              (v) => _settings!.socialLinks.twitter = v,
              icon: FontAwesomeIcons.twitter,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              "Facebook",
              _settings!.socialLinks.facebook ?? '',
              (v) => _settings!.socialLinks.facebook = v,
              icon: FontAwesomeIcons.facebook,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildCard(
        title: "إعدادات التنبيهات",
        icon: Icons.notifications,
        child: Column(
          children: [
            _buildSwitch(
              "البريد الإلكتروني",
              "استلام تحديثات عبر الإيميل",
              _settings!.notifications.email,
              (v) => setState(() => _settings!.notifications.email = v),
            ),
            const Divider(),
            _buildSwitch(
              "إشعارات التطبيق",
              "استلام إشعارات فورية",
              _settings!.notifications.push,
              (v) => setState(() => _settings!.notifications.push = v),
            ),
            const Divider(),
            _buildSwitch(
              "رسائل SMS",
              "استلام تحديثات عبر الرسائل النصية",
              _settings!.notifications.sms,
              (v) => setState(() => _settings!.notifications.sms = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildCard(
        title: "الخصوصية",
        icon: Icons.privacy_tip,
        child: Column(
          children: [
            _buildSwitch(
              "إظهار البريد الإلكتروني",
              "عرض الإيميل في صفحة المتجر العامة",
              _settings!.privacy.showEmail,
              (v) => setState(() => _settings!.privacy.showEmail = v),
            ),
            const Divider(),
            _buildSwitch(
              "إظهار رقم الهاتف",
              "عرض رقم الهاتف للعملاء",
              _settings!.privacy.showPhone,
              (v) => setState(() => _settings!.privacy.showPhone = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Current Subscription
          if (_subscription != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.cyan.shade50, Colors.blue.shade50],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyan.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _subscription!.planName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${_subscription!.price} SAR / شهر",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusChip(_subscription!.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              // يمنع النص من الخروج
                              child: Text(
                                "البداية: ${_formatDate(_subscription!.startDate)}",
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // تاريخ النهاية
                      Expanded(
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .end, // محاذاة لليسار (أو اليمين حسب اللغة)
                          children: [
                            const Icon(
                              Icons.event_busy,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "النهاية: ${_formatDate(_subscription!.endDate)}",
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_subscription!.status == 'active') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelSubscription,
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text("إلغاء الاشتراك"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            _buildEmptyState("لا يوجد اشتراك نشط", Icons.diamond),

          const SizedBox(height: 20),

          // History
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              "سجل الاشتراكات",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 10),
          ..._history
              .map(
                (sub) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 5),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.planName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${_formatDate(_subscription!.startDate)}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildStatusChip(sub.status, isSmall: true),
                          Text(
                            "${sub.price} SAR",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: rose500),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items) {
    return DropdownButtonFormField<String>(
      value: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {},
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: rose500,
    );
  }

  Widget _buildStatusChip(String status, {bool isSmall = false}) {
    Color color = Colors.grey;
    String text = status;
    if (status == 'active') {
      color = Colors.green;
      text = "نشط";
    }
    if (status == 'cancelled') {
      color = Colors.orange;
      text = "ملغى";
    }
    if (status == 'inactive') {
      color = Colors.red;
      text = "غير نشط";
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: isSmall ? 10 : 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 50, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(msg, style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
