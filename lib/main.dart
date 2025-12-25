import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// استيراد الشاشات والخدمات
import 'features/layout/main_layout_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart'; // تأكد من المسار

void main() async {
  // 1. تهيئة الـ Flutter Engine للعمليات غير المتزامنة
  WidgetsFlutterBinding.ensureInitialized();

  // 2. محاولة تسجيل الدخول التلقائي (قراءة التوكن وجلب البيانات)
  await AuthService.instance.tryAutoLogin();

  // 3. تشغيل التطبيق
  runApp(const LinyoraApp());
}

class LinyoraApp extends StatelessWidget {
  const LinyoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linyora',

      // إعدادات اللغة
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'), // العربية
        Locale('en'), // الإنجليزية
      ],
      locale: const Locale('ar'), // اللغة الافتراضية

      debugShowCheckedModeBanner: false,

      // الثيم والتصميم
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF105C6), // لون Linyora الوردي
          primary: const Color(0xFFF105C6),
        ),
        useMaterial3: true,
        fontFamily: 'Cairo', // تأكد من إضافة الخط في pubspec.yaml
        scaffoldBackgroundColor: Colors.white,
      ),

      // إجبار الاتجاه من اليمين لليسار
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },

      // تحديد الصفحة الأولى بناءً على حالة تسجيل الدخول
      home:
          AuthService.instance.isLoggedIn
              ? const MainLayoutScreen()
              : const LoginScreen(),

      // تعريف المسارات (مفيد للـ Drawer وزر تسجيل الخروج)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainLayoutScreen(),
      },
    );
  }
}
