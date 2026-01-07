import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // تأكد من إضافتها أو استبدلها بأيقونات عادية
import 'package:url_launcher/url_launcher.dart';

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
              const Color(
                0xFFF105C6,
              ).withOpacity(0.15), // لون البراند في الأعلى
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
              const Text(
                "Linyora ليس مجرد تطبيق، إنه مجتمع!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF105C6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "نجمع بين متعة مشاهدة الفيديوهات القصيرة وسهولة التسوق الإلكتروني. اكتشف أحدث الصيحات، تابع مشاهيرك المفضلين، واطلب المنتجات التي تحبها بضغطة زر.",
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
                title: "زيارة موقعنا الإلكتروني",
                onTap: () => _launchUrl('https://linyora.com'),
              ),
              _buildInfoTile(
                icon: Icons.privacy_tip_outlined,
                title: "سياسة الإسترجاع",
                onTap: () => _launchUrl('https://linyora.com/policy'),
              ),
              _buildInfoTile(
                icon: Icons.description_outlined,
                title: "شروط الاستخدام",
                onTap: () => _launchUrl('https://linyora.com/terms'),
              ),
              _buildInfoTile(
                icon: Icons.support_agent,
                title: "مركز المساعدة",
                onTap: () => _launchUrl('https://linyora.com/help'),
              ),

              const SizedBox(height: 40),

              // 4. التواصل الاجتماعي
              const Text(
                "تابعنا على",
                style: TextStyle(
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
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                "© 2024 Linyora Inc. All rights reserved.",
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
            // child: Icon(Icons.shopping_bag, size: 50, color: Colors.black), // مؤقت
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
