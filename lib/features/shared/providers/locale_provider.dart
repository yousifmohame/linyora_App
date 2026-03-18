import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  Locale get locale => _locale;

  // عند تشغيل المزوّد، نقوم بجلب اللغة المحفوظة
  LocaleProvider() {
    _loadSavedLocale();
  }

  // دالة لقراءة اللغة من الذاكرة
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('language_code');
    if (savedLanguageCode != null) {
      _locale = Locale(savedLanguageCode);
      notifyListeners();
    }
  }

  // دالة لتغيير اللغة وحفظها
  Future<void> setLocale(Locale locale) async {
    if (!L10n.all.contains(locale)) return;

    _locale = locale;
    notifyListeners();

    // حفظ الاختيار في الذاكرة
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  // تبديل اللغة (Toggle)
  Future<void> toggleLocale() async {
    final newLocale =
        _locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    await setLocale(newLocale);
  }
}

class L10n {
  static final all = [const Locale('ar'), const Locale('en')];
}
