import 'dart:async'; // للمؤقت
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linyora_project/models/notification_model.dart';
import 'package:linyora_project/features/home/services/home_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final HomeService _homeService = HomeService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  Timer? _pollingTimer; // مؤقت للتحديث التلقائي

  @override
  void initState() {
    super.initState();
    _fetchNotifications();

    // ========================================================
    // محاكاة منطق الموقع: تحديث البيانات كل 30 ثانية
    // ========================================================
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchNotifications(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // إيقاف المؤقت عند الخروج
    super.dispose();
  }

  // دالة الجلب (مع خيار الخلفية لعدم إظهار لودينج كل مرة)
  Future<void> _fetchNotifications({bool isBackground = false}) async {
    if (!isBackground) setState(() => _isLoading = true);

    final data = await _homeService.getNotifications();

    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  // دالة تحديد الكل كمقروء
  Future<void> _markAllAsRead() async {
    // 1. تحديث الواجهة فورياً (Optimistic UI)
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });

    // 2. إرسال الطلب للسيرفر
    final success = await _homeService.markAllNotificationsAsRead();

    // 3. إذا فشل الطلب، نعيد تحميل البيانات الأصلية
    if (!success) {
      _fetchNotifications(isBackground: true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("فشل تحديث الإشعارات")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "الإشعارات",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.isNotEmpty && _notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text("قراءة الكل"),
            ),
        ],
      ),
      // إضافة خاصية السحب للتحديث (Pull to Refresh)
      body: RefreshIndicator(
        onRefresh: () async => await _fetchNotifications(isBackground: true),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // لضمان عمل السحب حتى لو القائمة قصيرة
                  itemCount: _notifications.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(_notifications[index]);
                  },
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        // لضمان عمل RefreshIndicator في الحالة الفارغة
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              "لا توجد إشعارات حالياً",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 100), // مساحة للسحب
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    IconData icon;
    Color color;

    // تخصيص الأيقونة حسب نوع الإشعار القادم من الباك اند
    switch (notification.type) {
      case 'order':
        icon = Icons.local_shipping_outlined;
        color = Colors.blue;
        break;
      case 'promo':
        icon = Icons.local_offer_outlined;
        color = Colors.orange;
        break;
      case 'system':
      default:
        icon = Icons.notifications_active_outlined;
        color = Colors.purple;
    }

    return Container(
      color: notification.isRead ? Colors.white : Colors.blue.withOpacity(0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              notification.message, // عرض نص الرسالة
              style: TextStyle(color: Colors.grey[700], height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy-MM-dd – hh:mm a').format(notification.createdAt),
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
        trailing:
            !notification.isRead
                ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                )
                : null,
      ),
    );
  }
}
