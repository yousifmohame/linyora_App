import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/notifications_service.dart';

class ModelNotificationsScreen extends StatefulWidget {
  const ModelNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<ModelNotificationsScreen> createState() => _ModelNotificationsScreenState();
}

class _ModelNotificationsScreenState extends State<ModelNotificationsScreen> {
  final NotificationsService _service = NotificationsService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  // الألوان الخاصة بالمودل
  final Color _roseColor = const Color(0xFFE11D48);

  @override
  void initState() {
    super.initState();
    _fetchNotifications();

    // ✅ التحديث التلقائي كل 30 ثانية
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _fetchNotifications(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications({bool isBackground = false}) async {
    if (!isBackground) setState(() => _isLoading = true);

    try {
      final data = await _service.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !isBackground) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    // Optimistic UI Update
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });

    final success = await _service.markAllAsRead();

    if (!success) {
      _fetchNotifications(isBackground: true); // Revert on failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل تحديث الحالة")),
        );
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
          onPressed: () => Navigator.pop(context, true), // نرجع true لتحديث الصفحة السابقة
        ),
        actions: [
          if (_notifications.isNotEmpty && _notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text("قراءة الكل", style: TextStyle(color: _roseColor)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: _roseColor,
        onRefresh: () async => await _fetchNotifications(isBackground: true),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _roseColor))
            : _notifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) => _buildNotificationItem(_notifications[index]),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              "لا توجد إشعارات جديدة",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    IconData icon;
    Color color;

    // ✅ تخصيص الأيقونات للمودل
    switch (notification.type) {
      case 'request': // طلب تعاون جديد
        icon = Icons.handshake_outlined;
        color = Colors.blue;
        break;
      case 'payment': // دفعة مالية
        icon = Icons.account_balance_wallet_outlined;
        color = Colors.green;
        break;
      case 'alert': // تنبيه
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications_active_outlined;
        color = _roseColor;
    }

    return Container(
      color: notification.isRead ? Colors.white : _roseColor.withOpacity(0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(notification.message, style: TextStyle(color: Colors.grey[700], height: 1.3)),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy-MM-dd – hh:mm a').format(notification.createdAt),
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: _roseColor, shape: BoxShape.circle),
              )
            : null,
      ),
    );
  }
}