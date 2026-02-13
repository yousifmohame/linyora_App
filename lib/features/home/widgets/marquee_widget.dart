import 'dart:async';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:linyora_project/features/home/services/home_service.dart';

class MarqueeWidget extends StatefulWidget {
  const MarqueeWidget({Key? key}) : super(key: key);

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  final HomeService _homeService = HomeService();

  String combinedMessage = "";
  bool _isLoading = true;

  // المتغيرات الجديدة للسرعة واللون
  double _velocity = 30.0;
  Color _backgroundColor = Colors.black; // لون افتراضي

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // دالة مساعدة لتحويل Hex String (#FFFFFF) إلى Color في Flutter
  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor"; // إضافة الشفافية (Alpha) إذا لم تكن موجودة
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.black; // لون احتياطي في حال الخطأ
    }
  }

  Future<void> _loadData() async {
    try {
      // 1. استخدام Future.wait لجلب كل البيانات في نفس الوقت (مثل Promise.all)
      final results = await Future.wait([
        _homeService.getMarqueeMessages(), // index 0
        _homeService.getMarqueeSpeed(), // index 1
        _homeService.getMarqueeColor(), // index 2
      ]);

      if (mounted) {
        setState(() {
          // معالجة الرسائل
          final messages = results[0] as List<String>;
          if (messages.isNotEmpty) {
            combinedMessage = messages.join("       •       ");
          } else {
            combinedMessage = "Welcome to Linora!";
          }

          // معالجة السرعة
          // ملاحظة: في الويب (CSS duration) الرقم الأعلى يعني أبطأ
          // في Flutter (Velocity) الرقم الأعلى يعني أسرع
          // لذا قد تحتاج لضبط المعادلة حسب رغبتك، هنا سنستخدم القيمة كما هي كسرعة بكسل/ثانية
          int speedFromApi = results[1] as int;
          _velocity = speedFromApi.toDouble() * 20.0;
          // إذا كانت السرعة بطيئة جداً في التطبيق مقارنة بالموقع، يمكنك ضربها في معامل:
          // _velocity = speedFromApi.toDouble() * 2;

          // معالجة اللون
          String colorString = results[2] as String;
          _backgroundColor = _parseColor(colorString);

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading marquee data: $e");
      if (mounted) {
        setState(() {
          combinedMessage = "Welcome to Linora!";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || combinedMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      decoration: BoxDecoration(
        color: _backgroundColor, // ✅ استخدام اللون القادم من الباك اند
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        // إزالة الحواف الدائرية ليطابق تصميم الويب (اختياري)
        // أو إبقاؤها حسب تصميم التطبيق
        // borderRadius: BorderRadius.circular(25),
        child: Marquee(
          text: combinedMessage,
          style: const TextStyle(
            color: Colors.white, // النص أبيض ليناسب الخلفيات الداكنة
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          scrollAxis: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          blankSpace: 50.0,
          velocity: _velocity, // ✅ استخدام السرعة القادمة من الباك اند
          pauseAfterRound: const Duration(
            seconds: 0,
          ), // الويب عادة لا يتوقف، جعلناه 0 ليكون مستمراً
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
