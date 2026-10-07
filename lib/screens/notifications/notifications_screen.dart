import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/notification.dart';
import '../../providers/notifications_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().fetchNotifications();
    });
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.read) return;
    await context.read<NotificationsProvider>().markRead(item.id);
  }

  Future<void> _markAllRead() async {
    await context.read<NotificationsProvider>().markAllRead();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديد كافة الإشعارات كمقروءة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationsProvider>();
    final notifications = prov.notifications;

    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('الإشعارات والتنبيهات'),
        actions: [
          if (notifications.any((n) => !n.read))
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'تحديد الكل كمقروء',
              onPressed: _markAllRead,
            ),
        ],
      ),
      body: prov.isLoading && notifications.isEmpty
          ? const LoadingState(message: 'جاري تحميل الإشعارات...')
          : prov.error != null && notifications.isEmpty
              ? ErrorState(message: prov.error!, onRetry: () => prov.fetchNotifications())
              : RefreshIndicator(
                  onRefresh: () => prov.fetchNotifications(),
                  color: AppTheme.primaryTeal,
                  child: notifications.isEmpty
                      ? const EmptyState(
                          title: 'لا توجد إشعارات',
                          message: 'لم يتم استلام أي تنبيهات جديدة حتى الآن',
                          icon: Icons.notifications_none_rounded,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = notifications[index];
                            return _buildNotificationCard(item);
                          },
                        ),
                ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final isUnread = !item.read;

    return Card(
      elevation: 0,
      color: isUnread ? Colors.teal.shade50.withOpacity(0.4) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread ? AppTheme.primaryTeal.withOpacity(0.4) : AppTheme.border,
          width: isUnread ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isUnread ? AppTheme.primaryTeal.withOpacity(0.15) : Colors.grey.shade100,
          child: Icon(
            _getNotificationIcon(item.type),
            color: isUnread ? AppTheme.primaryTeal : AppTheme.textMuted,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryTeal,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.message,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            if (item.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                item.createdAt!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ],
        ),
        onTap: () => _markRead(item),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline_rounded;
      case 'danger':
        return Icons.error_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }
}
