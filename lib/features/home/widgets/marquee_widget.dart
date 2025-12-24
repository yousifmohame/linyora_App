import 'dart:async';
import 'package:flutter/material.dart';
import 'package:linyora_project/features/home/services/home_service.dart'; // تأكد من المسار الصحيح

class MarqueeWidget extends StatefulWidget {
  const MarqueeWidget({Key? key}) : super(key: key);

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  // تعريف السيرفس
  final HomeService _homeService = HomeService();

  List<String> messages = [];
  int currentIndex = 0;
  Timer? _timer;
  bool _isLoading = true; // لمعرفة حالة التحميل

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // دالة جلب الرسائل الحقيقية
  Future<void> _loadMessages() async {
    try {
      // استدعاء الدالة الحقيقية من السيرفس
      final fetchedMessages = await _homeService.getMarqueeMessages();

      if (mounted) {
        setState(() {
          messages = fetchedMessages;
          _isLoading = false;
        });

        // تشغيل المؤقت فقط إذا كان هناك أكثر من رسالة
        if (messages.length > 1) {
          _startTimer();
        }
      }
    } catch (e) {
      debugPrint("Error in MarqueeWidget: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          currentIndex = (currentIndex + 1) % messages.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. إذا كان لا يزال يحمل أو القائمة فارغة، قم بإخفاء الويجت
    if (_isLoading || messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.blueAccent, // يمكنك تغيير اللون هنا
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Text(
          messages[currentIndex],
          // المفتاح ضروري لعمل الأنيميشن عند تغيير النص
          key: ValueKey<String>(messages[currentIndex]),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
