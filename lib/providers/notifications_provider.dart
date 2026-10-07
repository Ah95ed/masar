import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/notification.dart';
import '../services/admin_api.dart';

/// موفر حالة الإشعارات والتنبيهات الحية
class NotificationsProvider extends ChangeNotifier {
  final AdminApi api;

  NotificationsProvider({AdminApi? api}) : api = api ?? AdminApi();

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await api.get('notifications');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['notifications'] ?? res['data'] ?? res['items'] ?? [];
      }
      _notifications = rawList
          .whereType<Map>()
          .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _isLoading = false;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
    } catch (_) {
      _error = 'حدث خطأ أثناء تحميل الإشعارات';
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<bool> markRead(int notificationId) async {
    try {
      await api.post('notification-read', {'notification_id': notificationId});
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        final old = _notifications[idx];
        _notifications[idx] = NotificationItem(
          id: old.id,
          title: old.title,
          message: old.message,
          type: old.type,
          link: old.link,
          isRead: 1,
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllRead() async {
    try {
      await api.post('notification-read-all', {});
      for (int i = 0; i < _notifications.length; i++) {
        final old = _notifications[i];
        _notifications[i] = NotificationItem(
          id: old.id,
          title: old.title,
          message: old.message,
          type: old.type,
          link: old.link,
          isRead: 1,
          createdAt: old.createdAt,
        );
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
