import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/merchant_dashboard_model.dart';

class SalesChart extends StatelessWidget {
  final List<SalesData> data;
  final bool isWeekly;

  const SalesChart({
    Key? key,
    required this.data,
    this.isWeekly = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // تجهيز الألوان المتدرجة (نفس ألوان الموقع)
    final List<Color> gradientColors = [
      const Color(0xFF8B5CF6).withOpacity(0.8), // Purple
      const Color(0xFF8B5CF6).withOpacity(0.1),
    ];

    return AspectRatio(
      aspectRatio: 1.70,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _calculateMaxY(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  // tooltipBgColor: Colors.blueGrey, // تم تحديث الخاصية في النسخ الحديثة إلى getTooltipColor
                  getTooltipColor: (group) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.round()} ر.س',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        // تنسيق التاريخ (مثلاً: 25 Jan)
                        final dateStr = data[index].date;
                        final date = DateTime.tryParse(dateStr);
                        final text = date != null ? DateFormat('d MMM').format(date) : '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox();
                      return Text(
                        _formatCurrency(value),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateInterval(),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.sales,
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    if (data.isEmpty) return 100;
    double max = data.map((e) => e.sales).reduce((curr, next) => curr > next ? curr : next);
    return max + (max * 0.2); // إضافة مساحة 20% في الأعلى
  }

  double _calculateInterval() {
    double max = _calculateMaxY();
    if (max <= 0) return 10;
    return max / 5; // تقسيم الشبكة لـ 5 خطوط
  }

  String _formatCurrency(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}