import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'features/layout/main_layout_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/shared/providers/locale_provider.dart';
import 'features/wishlist/providers/wishlist_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.tryAutoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        // تسجيل مزود اللغة هنا
        ChangeNotifierProvider(create: (_) => LocaleProvider()), 
        ChangeNotifierProvider(create: (_) => WishlistProvider()..fetchWishlist()),
      ],
      child: const LinyoraApp(),
    ),
  );
}

class LinyoraApp extends StatelessWidget {
  const LinyoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام Consumer للاستماع لتغييرات اللغة
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: 'Linyora',
          
          // ربط اللغة بالبروفايدر
          locale: localeProvider.locale, 
          
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.all,

          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF105C6),
              primary: const Color(0xFFF105C6),
            ),
            useMaterial3: true,
            fontFamily: 'Cairo',
            scaffoldBackgroundColor: Colors.white,
          ),
          
          // هذا السطر مهم جداً لتحديد اتجاه النص تلقائياً بناءً على اللغة
          builder: (context, child) {
            final dir = localeProvider.locale.languageCode == 'ar' 
                ? TextDirection.rtl 
                : TextDirection.ltr;
            return Directionality(textDirection: dir, child: child!);
          },

          home: AuthService.instance.isLoggedIn
              ? const MainLayoutScreen()
              : const LoginScreen(),
              
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const MainLayoutScreen(),
          },
        );
      },
    );
  }
}