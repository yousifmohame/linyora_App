import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

// Providers
import 'features/address/providers/address_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/payment/providers/payment_provider.dart';
import 'features/trends/providers/trend_provider.dart';
import 'features/wishlist/providers/wishlist_provider.dart';
import 'features/shared/providers/locale_provider.dart';

// Services & Screens
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/auth_dispatcher.dart'; // ✅ الملف الذي أنشأناه في الخطوة 2
import 'features/layout/main_layout_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعداد Stripe
  Stripe.publishableKey =
      'pk_test_51QMVVaRprtRJ29NO563CM9I4Fj1p1xVaz5Dyvo6GBg5bxCvJlSQPOfCxa0KD7cBjL9MJcq8uQDUyPfkWgbOqNZZs00wlW9KrBI';
  await Stripe.instance.applySettings();

  runApp(
    MultiProvider(
      providers: [
        // ✅ AuthProvider يجب أن يسمى initAuth عند إنشائه
        ChangeNotifierProvider(create: (_) => AuthProvider()..initAuth()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(
          create: (_) => WishlistProvider()..fetchWishlist(),
        ),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => TrendProvider()),
      ],
      child: const LinyoraApp(),
    ),
  );
}

class LinyoraApp extends StatelessWidget {
  const LinyoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: 'Linyora',
          debugShowCheckedModeBanner: false,

          // إعدادات اللغة
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.all,

          // الثيم
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF105C6),
              primary: const Color(0xFFF105C6),
            ),
            useMaterial3: true,
            fontFamily: 'Cairo',
            scaffoldBackgroundColor: Colors.white,
          ),

          // ضبط اتجاه النص (RTL/LTR)
          builder: (context, child) {
            final dir =
                localeProvider.locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr;
            return Directionality(textDirection: dir, child: child!);
          },

          // ✅ هنا التوجيه الذكي باستخدام AuthDispatcher
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              // 1. حالة التحميل (سبلاش سكرين)
              if (auth.isLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // 2. حالة عدم التسجيل
              if (!auth.isLoggedIn || auth.user == null) {
                return const MainLayoutScreen();
              }

              // 3. حالة التسجيل -> نرسل المستخدم للموجه
              return AuthDispatcher(user: auth.user!);
            },
          ),

          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const MainLayoutScreen(),
          },
        );
      },
    );
  }
}
