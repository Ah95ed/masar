import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/notification.dart';
import '../../providers/notifications_provider.dart';
import '../../services/admin_api.dart';
import '../../widgets/auto_refresh_wrapper.dart';

import '../../widgets/state_view.dart';
import '../reports/reports_screen.dart';
import '../reports/report_detail_screen.dart';
import '../sites/sites_screen.dart';
import '../tasks/tasks_screen.dart';
import '../updates/work_updates_screen.dart';
import '../users/pending_users_screen.dart';
import '../warehouse/warehouse_items_screen.dart';
import '../warehouse/warehouse_moves_screen.dart';

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
        content: Text('تم تعليم جميع الإشعارات كمقروءة', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: kGreen,
      ),
    );
  }

  MaterialPageRoute? _mapLinkToScreen(String link) {
    if (link.startsWith('admin/reports.php') || link.startsWith('reports.php')) {
      final uri = Uri.tryParse('https://x/$link');
      final q = uri?.queryParameters ?? {};
      final id = int.tryParse(q['id'] ?? '');
      if (id != null) {
        return MaterialPageRoute(builder: (_) => ReportDetailScreen(api: widget.api, reportId: id));
      }
      return MaterialPageRoute(builder: (_) => ReportsScreen(api: widget.api));
    }
    if (link.startsWith('admin/work_updates.php') || link.startsWith('work_updates.php') || link.startsWith('work-updates')) {
      final uri = Uri.tryParse('https://x/$link');
      final q = uri?.queryParameters ?? {};
      return MaterialPageRoute(
        builder: (_) => WorkUpdatesScreen(
          api: widget.api,
          planId: int.tryParse(q['plan'] ?? q['plan_id'] ?? ''),
        ),
      );
    }
    if (link.startsWith('admin/sites.php') || link.startsWith('sites.php')) {
      return MaterialPageRoute(builder: (_) => SitesScreen(api: widget.api));
    }
    if (link.startsWith('admin/work_plans.php') || link.startsWith('work_plans.php') || link.startsWith('tasks.php')) {
      return MaterialPageRoute(builder: (_) => TasksScreen(api: widget.api));
    }
    if (link.startsWith('admin/pending_users.php') || link.startsWith('pending_users.php')) {
      return MaterialPageRoute(builder: (_) => PendingUsersScreen(api: widget.api));
    }
    if (link.startsWith('admin/warehouse_items.php') || link.startsWith('warehouse_items.php')) {
      return MaterialPageRoute(builder: (_) => WarehouseItemsScreen(api: widget.api));
    }
    if (link.startsWith('admin/warehouse_moves.php') || link.startsWith('warehouse_moves.php')) {
      return MaterialPageRoute(builder: (_) => WarehouseMovesScreen(api: widget.api));
    }
    if (link.startsWith('engineer/dashboard.php')) {
      return MaterialPageRoute(builder: (_) => ReportsScreen(api: widget.api));
    }
    if (link.startsWith('engineer/tasks.php')) {
      return MaterialPageRoute(builder: (_) => TasksScreen(api: widget.api));
    }
    return null;
  }

  Future<void> _handleNotificationTap(NotificationItem item) async {
    if (!item.read) {
      await _markRead(item);
    }
    final link = item.link;
    if (link != null && link.isNotEmpty) {
      final route = _mapLinkToScreen(link);
      if (route != null && mounted) {
        Navigator.push(context, route);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationsProvider>();
    final notifications = prov.notifications;
    final isWide = MediaQuery.of(context).size.width >= 750;

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 10),
      onRefresh: () => prov.fetchNotifications(),
      child: Scaffold(
        drawer: widget.drawer,
        appBar: AppBar(
          title: const Text('الإشعارات والتنبيهات'),
          actions: [
            if (notifications.any((n) => !n.read))
              IconButton(
                icon: const Icon(Icons.done_all_rounded),
                tooltip: 'تعليم الكل كمقروء',
                onPressed: _markAllRead,
              ),
          ],
        ),
        body: StateView(
          loading: prov.isLoading && notifications.isEmpty,
          error: prov.error,
          empty: notifications.isEmpty,
          emptyMessage: 'لا توجد تنبيهات جديدة حتى الآن',
          onRetry: () => prov.fetchNotifications(),
          child: RefreshIndicator(
            onRefresh: () => prov.fetchNotifications(),
            color: kCyan,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kLine),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مركز التنبيهات الإدارية',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: kInk),
                          ),
                          Text(
                            '${prov.unreadCount} إشعار غير مقروء · تحديث فوري كل 10 ثوان',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: kMuted),
                          ),
                        ],
                      ),
                      if (prov.unreadCount > 0)
                        FilledButton.tonalIcon(
                          onPressed: _markAllRead,
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label: const Text('تعليم كمقروء', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (isWide)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 520,
                      mainAxisExtent: 145,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) => _buildNotificationCard(notifications[index]),
                  )
                else
                  ...notifications.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildNotificationCard(n),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final isUnread = !item.read;

    return Card(
      elevation: 0,
      color: isUnread ? kCyanPale.withOpacity(0.35) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isUnread ? kCyan.withOpacity(0.5) : kLine,
          width: isUnread ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(item),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _getNotificationColor(item.type).withOpacity(0.15),
                    child: Icon(_getNotificationIcon(item.type), color: _getNotificationColor(item.type), size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title + (isUnread ? ' · جديد' : ''),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                        color: isUnread ? kInk : AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.createdAt != null)
                    Text(item.createdAt!, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: kMuted)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isUnread)
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.check_rounded, size: 14, color: kGreen),
                      label: const Text('تمت القراءة', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kGreen)),
                      onPressed: () => _markRead(item),
                    ),
                  if (item.link != null && item.link!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.open_in_new_rounded, size: 14, color: kCyan),
                      label: const Text('فتح', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: kCyan, fontWeight: FontWeight.bold)),
                      onPressed: () => _handleNotificationTap(item),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'report_submitted':
      case 'report_pending':
        return kAmber;
      case 'urgent_task':
      case 'alert':
        return kRed;
      case 'warehouse_signed':
      case 'success':
        return kGreen;
      default:
        return kCyan;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'report_submitted':
      case 'report_pending':
        return Icons.assignment_outlined;
      case 'urgent_task':
        return Icons.notification_important_rounded;
      case 'warehouse_signed':
        return Icons.verified_outlined;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}
