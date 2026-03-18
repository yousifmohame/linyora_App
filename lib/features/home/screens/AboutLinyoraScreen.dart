import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // تأكد من إضافتها أو استبدلها بأيقونات عادية
import 'package:url_launcher/url_launcher.dart';

// ✅ 1. استيراد ملف الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

class AboutLinyoraScreen extends StatelessWidget {
  const AboutLinyoraScreen({Key? key}) : super(key: key);

  // دالة لفتح الروابط
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف ملف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black, // خلفية داكنة
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        // خلفية بتدرج لوني خفيف جداً لإعطاء عمق
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF105C6).withOpacity(0.15), // لون البراند في الأعلى
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // 1. الشعار واسم التطبيق
              _buildLogoSection(),

              const SizedBox(height: 30),

              // 2. نبذة عن التطبيق
              Text(
                l10n.aboutTitle, // ✅ نص مترجم
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF105C6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.aboutDescription, // ✅ نص مترجم
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // 3. قائمة الروابط والمعلومات
              _buildInfoTile(
                icon: Icons.language,
                title: l10n.visitWebsite, // ✅ نص مترجم
                onTap: () => _launchUrl('https://linyora.com'),
              ),
              _buildInfoTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.returnPolicy, // ✅ نص مترجم
                onTap: () => _launchUrl('https://linyora.com/policy'),
              ),
              _buildInfoTile(
                icon: Icons.description_outlined,
                title: l10n.termsOfUse, // ✅ نص مترجم
                onTap: () => _launchUrl('https://linyora.com/terms'),
              ),
              _buildInfoTile(
                icon: Icons.support_agent,
                title: l10n.helpCenter, // ✅ نص مترجم
                onTap: () => _launchUrl('https://linyora.com/help'),
              ),

              const SizedBox(height: 40),

              // 4. التواصل الاجتماعي
              Text(
                l10n.followUs, // ✅ نص مترجم
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    FontAwesomeIcons.facebookF,
                    "https://facebook.com",
                  ),
                  const SizedBox(width: 20),
                  _buildSocialButton(
                    FontAwesomeIcons.instagram,
                    "https://instagram.com",
                  ),
                  const SizedBox(width: 20),
                  _buildSocialButton(
                    FontAwesomeIcons.tiktok,
                    "https://tiktok.com",
                  ),
                  const SizedBox(width: 20),
                  _buildSocialButton(
                    FontAwesomeIcons.twitter,
                    "https://twitter.com",
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // 5. الحقوق والإصدار
              Text(
                "${l10n.version} 1.0.0", // ✅ استخدام متغير Version الموجود مسبقاً
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.copyright, // ✅ نص مترجم
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت الشعار
  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF105C6), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF105C6).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            // ضع مسار اللوجو الخاص بك هنا
            backgroundImage: AssetImage('assets/images/logo.png'),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Linyora",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ويدجت عناصر القائمة
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFFF105C6)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // ويدجت أزرار السوشيال ميديا
  Widget _buildSocialButton(IconData icon, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}