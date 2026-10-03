import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/management_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';
import '../widgets/responsive_container.dart';

/// شاشة إشعارات وتنبيهات الإدارة العامة
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagementProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الإشعارات والتنبيهات الإدارية'),
        actions: [
          if (provider.unreadNotificationsCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('قراءة الكل'),
              onPressed: () => provider.markAllNotificationsRead(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: () => provider.fetchNotifications(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.notificationsState == LoadingState.loading && provider.notifications.isEmpty) {
            return const LoadingWidget(message: 'جاري تحميل الإشعارات...');
          }

          if (provider.notificationsState == LoadingState.error && provider.notifications.isEmpty) {
            return ErrorView(
              message: provider.notificationsError ?? 'تعذر تحميل الإشعارات',
              onRetry: () => provider.fetchNotifications(),
            );
          }

          if (provider.notifications.isEmpty) {
            return const EmptyView(
              title: 'لا توجد إشعارات حالياً',
              message: 'ستظهر هنا تنبيهات رفع التقارير، نقص المخزون، وتحديثات الصيانة.',
              icon: Icons.notifications_none_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            color: const Color(0xFF0F172A),
            child: ResponsiveContainer(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: ListView.separated(
                itemCount: provider.notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = provider.notifications[index];
                  final isUnread = !item.isRead;

                  return Card(
                    elevation: 0,
                    color: isUnread ? Colors.white : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isUnread ? const Color(0xFF0284C7).withValues(alpha: 0.4) : Colors.grey.shade200,
                        width: isUnread ? 1.5 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (isUnread) {
                          provider.markNotificationRead(item.id);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isUnread ? const Color(0xFF0284C7).withValues(alpha: 0.12) : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isUnread ? Icons.mark_email_unread_rounded : Icons.mark_email_read_outlined,
                                size: 20,
                                color: isUnread ? const Color(0xFF0284C7) : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (isUnread)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF59E0B),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Text(
                                            'جديد',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                  if (item.createdAt != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      item.createdAt!,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
