import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/notification.dart';
import '../../services/admin_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class NotificationsScreen extends StatefulWidget {
  final AdminApi api;
  final Widget? drawer;

  const NotificationsScreen({super.key, required this.api, this.drawer});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ✅ جلب الإشعارات دائماً من السيرفر
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.get('notifications');
      if (!mounted) return;
      setState(() {
        _notifications = (res as List).map((e) => NotificationItem.fromJson(e)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ أثناء تحميل الإشعارات';
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationItem item) async {
    if (item.read) return;
    try {
      await widget.api.post('notification-read', {'id': item.id});
      if (!mounted) return;
      // ✅ إعادة الجلب التلقائي من السيرفر
      await _load();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await widget.api.post('notification-read-all', {});
      if (!mounted) return;
      // ✅ إعادة الجلب التلقائي من السيرفر
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تعليم جميع الإشعارات كمقروءة', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.read).length;

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('مركز الإشعارات والتنبيهات'),
        // ⚠️ لا يوجد زر Refresh في الـ AppBar
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'تعليم الكل كمقروء',
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _loading
          ? const LoadingState(message: 'جاري تحميل التنبيهات...')
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryTeal,
                  child: _notifications.isEmpty
                      ? const EmptyState(
                          title: 'لا توجد إشعارات',
                          message: 'صندوق التنبيهات فارغ حالياً',
                          icon: Icons.notifications_none_rounded,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final item = _notifications[index];
                            return _buildNotificationCard(item);
                          },
                        ),
                ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: item.read ? AppTheme.surface : AppTheme.primaryTeal.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.read ? AppTheme.border : AppTheme.primaryTeal.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: item.read ? AppTheme.border : AppTheme.primaryTeal.withOpacity(0.15),
          child: Icon(
            item.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
            color: item.read ? AppTheme.textMuted : AppTheme.primaryTeal,
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: item.read ? FontWeight.normal : FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              item.message,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
            ),
            if (item.createdAt != null && item.createdAt!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.createdAt!,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: AppTheme.textMuted),
              ),
            ],
          ],
        ),
        onTap: () => _markAsRead(item),
      ),
    );
  }
}