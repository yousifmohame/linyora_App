import 'package:flutter/material.dart';

class ColorHelper {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // دالة لتعديل اللون (أغمق أو أفتح) لعمل التدرج
  static Color adjustColor(Color color, {int amount = 0}) {
    assert(amount >= -255 && amount <= 255);

    final r = (color.r * 255 + amount).clamp(0, 255).toInt();
    final g = (color.g * 255 + amount).clamp(0, 255).toInt();
    final b = (color.b * 255 + amount).clamp(0, 255).toInt();

    return Color.fromARGB(255, r, g, b);
  }
}