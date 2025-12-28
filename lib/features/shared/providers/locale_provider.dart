import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  // اللغة الافتراضية (العربية)
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!L10n.all.contains(locale)) return;
    _locale = locale;
    notifyListeners(); // تحديث التطبيق بالكامل
  }

  // تبديل اللغة (Toggle)
  void toggleLocale() {
    _locale = _locale.languageCode == 'ar' 
        ? const Locale('en') 
        : const Locale('ar');
    notifyListeners();
  }
}

class L10n {
  static final all = [
    const Locale('ar'),
    const Locale('en'),
  ];
}