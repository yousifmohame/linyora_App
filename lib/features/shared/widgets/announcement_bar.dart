import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class AnnouncementBar extends StatelessWidget {
  final List<String> messages;

  const AnnouncementBar({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();

    // دمج الرسائل في نص واحد مع فواصل
    final String fullText = messages.join("   •   ");

    return Container(
      height: 36, // ارتفاع الشريط (رفيع)
      width: double.infinity,
      color: Colors.black, // خلفية سوداء (أو لون الثيم الخاص بك)
      child: Marquee(
        text: fullText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        blankSpace: 50.0, // مسافة فارغة بعد انتهاء النص
        velocity: 30.0,   // سرعة الحركة (30 مناسبة للقراءة)
        pauseAfterRound: const Duration(seconds: 1),
        startPadding: 10.0,
        accelerationDuration: const Duration(seconds: 1),
        accelerationCurve: Curves.linear,
        decelerationDuration: const Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
        textDirection: TextDirection.rtl, // اتجاه النص للعربية
      ),
    );
  }
}