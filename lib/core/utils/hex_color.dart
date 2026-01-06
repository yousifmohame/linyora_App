import 'package:flutter/material.dart';

class HexColor {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      // لون افتراضي في حال كان الكود القادم من السيرفر خطأ
      return Colors.black; 
    }
  }
}