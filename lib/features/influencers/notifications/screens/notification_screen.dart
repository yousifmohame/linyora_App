import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ 1. استيراد ملف الترجمة
import 'package:linyora_project/l10n/app_localizations.dart';

import '../models/notification_model.dart';
import '../services/notifications_service.dart';

class ModelNotificationsScreen extends StatefulWidget {
  const ModelNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<ModelNotificationsScreen> createState() =>
      _ModelNotificationsScreenState();
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

    // التحديث التلقائي كل 30 ثانية
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

  // ✅ تمرير l10n للسناك بار
  Future<void> _markAllAsRead(AppLocalizations l10n) async {
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
          SnackBar(content: Text(l10n.failedToUpdateStatus)), // ✅ مترجم
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. تعريف الترجمة
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.notificationsTitle, // ✅ مترجم
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          if (_notifications.isNotEmpty && _notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => _markAllAsRead(l10n), // ✅ تمرير l10n
              child: Text(
                l10n.markAllAsReadBtn,
                style: TextStyle(color: _roseColor),
              ), // ✅ مترجم
            ),
        ],
      ),
      body: RefreshIndicator(
        color: _roseColor,
        onRefresh: () async => await _fetchNotifications(isBackground: true),
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator(color: _roseColor))
                : _notifications.isEmpty
                ? _buildEmptyState(l10n) // ✅ تمرير l10n
                : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _notifications.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder:
                      (context, index) =>
                          _buildNotificationItem(_notifications[index]),
                ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
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
            Text(
              l10n.noNewNotificationsMsg, // ✅ مترجم
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
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

    switch (notification.type) {
      case 'request':
        icon = Icons.handshake_outlined;
        color = Colors.blue;
        break;
      case 'payment':
        icon = Icons.account_balance_wallet_outlined;
        color = Colors.green;
        break;
      case 'alert':
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications_active_outlined;
        color = _roseColor;
    }

    // ✅ جلب كود اللغة الحالي لضبط تنسيق التاريخ والوقت AM/PM لتصبح ص/م في العربية
    String langCode = Localizations.localeOf(context).languageCode;

    return Container(
      color: notification.isRead ? Colors.white : _roseColor.withOpacity(0.05),
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
              notification.message,
              style: TextStyle(color: Colors.grey[700], height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat(
                'yyyy-MM-dd – hh:mm a',
                langCode,
              ).format(notification.createdAt), // ✅ وقت ديناميكي
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
        trailing:
            !notification.isRead
                ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _roseColor,
                    shape: BoxShape.circle,
                  ),
                )
                : null,
      ),
    );
  }
}
