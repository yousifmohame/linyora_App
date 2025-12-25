import 'dart:async';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart'; // 1. استيراد المكتبة
import 'package:linyora_project/features/home/services/home_service.dart';

class MarqueeWidget extends StatefulWidget {
  const MarqueeWidget({Key? key}) : super(key: key);

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  final HomeService _homeService = HomeService();

  // بدلاً من قائمة ورقم حالي، سنستخدم نصاً واحداً طويلاً
  String combinedMessage = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // لا نحتاج لـ dispose للتايمر لأنه تم حذفه

  Future<void> _loadMessages() async {
    try {
      final fetchedMessages = await _homeService.getMarqueeMessages();

      if (mounted) {
        setState(() {
          // 2. دمج جميع الرسائل في نص واحد مع فواصل
          if (fetchedMessages.isNotEmpty) {
            // نضع مسافات ونقطة بين كل رسالة والأخرى
            combinedMessage = fetchedMessages.join("       •       ");
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error in MarqueeWidget: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || combinedMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 40, // 3. ضروري تحديد ارتفاع ثابت للشريط المتحرك
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      // إزالة الـ padding العمودي الداخلي لأن Marquee يحتاج مساحة للحركة
      decoration: BoxDecoration(
        color: Colors.blueAccent,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // 4. قص المحتوى لضمان عدم خروج النص عن الحواف الدائرية
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Marquee(
          text: combinedMessage,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          scrollAxis: Axis.horizontal, // اتجاه الحركة
          crossAxisAlignment: CrossAxisAlignment.center,
          blankSpace: 50.0, // مسافة فارغة بعد انتهاء النص وقبل بدايته مجدداً
          velocity: 30.0, // سرعة الحركة (كلما زاد الرقم زادت السرعة)
          pauseAfterRound: const Duration(seconds: 1), // توقف لحظي بعد كل دورة
          startPadding: 10.0,
          accelerationDuration: const Duration(seconds: 1),
          accelerationCurve: Curves.linear,
          decelerationDuration: const Duration(milliseconds: 500),
          decelerationCurve: Curves.easeOut,
        ),
      ),
    );
  }
}
