import 'dart:async';
import 'package:flutter/material.dart';

class FlashSaleTimer extends StatefulWidget {
  final DateTime endTime;
  const FlashSaleTimer({super.key, required this.endTime});

  @override
  State<FlashSaleTimer> createState() => _FlashSaleTimerState();
}

class _FlashSaleTimerState extends State<FlashSaleTimer> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTime());
  }

  void _calculateTime() {
    final now = DateTime.now();
    final difference = widget.endTime.difference(now);

    if (difference.isNegative) {
      _timer.cancel();
      setState(() => _timeLeft = Duration.zero);
    } else {
      setState(() => _timeLeft = difference);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.inSeconds <= 0) return const SizedBox.shrink();

    return Row(
      textDirection: TextDirection.ltr, // لضمان ترتيب الأرقام (ساعات:دقائق)
      children: [
        _buildTimeBox(_timeLeft.inSeconds.remainder(60), "ث"),
        _buildSeparator(),
        _buildTimeBox(_timeLeft.inMinutes.remainder(60), "د"),
        _buildSeparator(),
        _buildTimeBox(_timeLeft.inHours.remainder(24), "س"),
        if (_timeLeft.inDays > 0) ...[
          _buildSeparator(),
          _buildTimeBox(_timeLeft.inDays, "ي"),
        ],
      ],
    );
  }

  Widget _buildTimeBox(int value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        value.toString().padLeft(2, '0'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.red[800],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(":", style: TextStyle(color: Colors.red[300], fontWeight: FontWeight.bold)),
    );
  }
}