import 'package:flutter/material.dart';
import 'package:linyora_project/features/layout/main_layout_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const LinyoraApp());
}

class LinyoraApp extends StatelessWidget {
  const LinyoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linyora',
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
      locale: const Locale('ar'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        fontFamily: 'Cairo', // يفضل إضافة خط عربي لاحقاً
      ),
      // جعل الاتجاه من اليمين لليسار (RTL) لأن التطبيق يستهدف العرب
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      // home: const LoginScreen(),
      home: const MainLayoutScreen(),
    );
  }
}
