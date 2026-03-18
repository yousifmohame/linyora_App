// helper/color_parser.dart أو في نفس الملف مؤقتاً
import 'package:flutter/material.dart';

class ColorParser {
  static Color? parse(String text) {
    String input = text.trim().toLowerCase();

    // 1. التحقق إذا كان Hex Code (مثل #FF0000)
    if (input.startsWith('#')) {
      try {
        final buffer = StringBuffer();
        if (input.length == 6 || input.length == 7) buffer.write('ff');
        buffer.write(input.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return null;
      }
    }

    // 2. قاموس الألوان (عربي & إنجليزي)
    final Map<String, Color> colorsMap = {
      // English
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'black': Colors.black,
      'white': Colors.white,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'brown': Colors.brown,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'cyan': Colors.cyan,
      'navy': const Color(0xFF000080),
      'gold': const Color(0xFFFFD700),
      'silver': const Color(0xFFC0C0C0),
      'beige': const Color(0xFFF5F5DC),
      'maroon': const Color(0xFF800000),
      
      // Arabic (التعرف على العربية)
      'أحمر': Colors.red,
      'احمر': Colors.red,
      'أخضر': Colors.green,
      'اخضر': Colors.green,
      'أزرق': Colors.blue,
      'ازرق': Colors.blue,
      'أسود': Colors.black,
      'اسود': Colors.black,
      'أبيض': Colors.white,
      'ابيض': Colors.white,
      'أصفر': Colors.yellow,
      'اصفر': Colors.yellow,
      'برتقالي': Colors.orange,
      'بنفسجي': Colors.purple,
      'موف': Colors.purple,
      'زهري': Colors.pink,
      'وردي': Colors.pink,
      'بمبي': Colors.pink,
      'بني': Colors.brown,
      'رمادي': Colors.grey,
      'رصاصي': Colors.grey,
      'سماوي': Colors.cyan,
      'كحلي': const Color(0xFF000080),
      'ذهبي': const Color(0xFFFFD700),
      'فضي': const Color(0xFFC0C0C0),
      'بيج': const Color(0xFFF5F5DC),
      'نبيتي': const Color(0xFF800000),
      'عنابي': const Color(0xFF800000),
    };

    return colorsMap[input];
  }
}