# 🔔 دليل وبرومبت نظام الإشعارات والتحديث اللحظي لتطبيق المهندس (Maxlond Engineer)

> **وثيقة متكاملة (End-to-End Guide):** توضح كافة خيارات التحديث اللحظي (WebSockets, Silent Auto-Polling, Local Notifications, Manual Refresh) مع المخطط البرمجي الشامل من الباك إند (PHP/MySQL) إلى تطبيق Flutter.

---

## 📑 جدول المحتويات

1. [مقارنة حلول التحديث اللحظي (WebSockets vs Polling vs SSE)](#1-مقارنة-حلول-التحديث-اللحظي)
2. [قاعدة البيانات وجداول الإشعارات (MySQL Schema)](#2-قاعدة-البيانات-mysql-schema)
3. [برمجة الباك إند وتوليد الإشعارات (PHP Endpoints & Triggers)](#3-برمجة-الباك-إند-php)
4. [الحل الأول: التحديث الصامت والربط التلقائي (Silent Polling & Cascade Refresh)](#4-الحل-الأول-التحديث-الصامت-cascade-polling)
5. [الحل الثاني: التحديث اللحظي بالويب سوكيت (WebSockets & SSE)](#5-الحل-الثاني-الويب-سوكيت-websockets--sse)
6. [الحل الثالث: أدوات التحديث اليدوي (Manual Pull & Button Refresh)](#6-الحل-الثالث-أدوات-التحديث-اليدوي)
7. [كود تطبيق المهندس الكامل (Flutter Architecture)](#7-كود-تطبيق-المهندس-flutter)
   - [المودل: NotificationModel](#المودل-notificationmodel)
   - [المزوّد: NotificationsProvider](#المزود-notificationsprovider)
   - [الأداة: AutoRefreshWrapper](#الأداة-autorefreshwrapper)
   - [شارة العداد: NotificationBadge](#شارة-العداد-notificationbadge)
   - [شاشة الإشعارات والتوجيه الذكي: NotificationsScreen](#شاشة-الإشعارات-والتوجيه-الذكي)
8. [التنبيهات الصوتية والمحلية (Audio & In-App Alerts)](#8-التنبيهات-الصوتية-والمحلية)

---

## 1. مقارنة حلول التحديث اللحظي

| الميزة               | Silent Auto-Polling (المطبق حالياً)                | WebSockets (ويب سوكيت)                                      | Server-Sent Events (SSE)            |
| -------------------- | -------------------------------------------------- | ----------------------------------------------------------- | ----------------------------------- |
| **سرعة الوصول**      | 10 إلى 15 ثانية                                    | فوري (خلال أجزاء من الثانية)                                | فوري (خلال ثانية)                   |
| **متطلبات السيرفر**  | سيرفر PHP عادي (Apache/Nginx) بدون أي برامج إضافية | يحتاج خادم خلفي دائم (Node.js أو Swoole أو خدمة مثل Pusher) | يحتاج ضبط اتصال مستمر في PHP/Nginx  |
| **استهلاك الموارد**  | خفيف جداً، يتوقف عند قفل الهاتف                    | يتطلب اتصال دائم TCP مفتوح                                  | اتصال أحادي الاتجاه                 |
| **السهولة والتوافق** | **متوافق 100% مع استضافة PHP الحالية**             | يتطلب إعداد خادم إضافي وإعادة تهيئة السيرفر                 | يتطلب دعم تدفق البيانات (Streaming) |
| **توصية المشروع**    | **الحل الأفضل والأسرع للتطبيق المباشر**            | ممتاز للمشاريع الكبيرة مستقبلاً                             | بديل خفيف للويب سوكيت               |

---

## 2. قاعدة البيانات (MySQL Schema)

نفّذ هذا الاستعلام في قاعدة بيانات السيرفر لإنشاء جدول الإشعارات وتجهيزه:

```sql
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL COMMENT 'معرف المهندس المستلم',
  `title` VARCHAR(255) NOT NULL COMMENT 'عنوان التنبيه',
  `message` TEXT NOT NULL COMMENT 'تفاصيل التنبيه أو ملاحظات المدير',
  `type` VARCHAR(50) DEFAULT 'info' COMMENT 'نوع الإشعار: task, report_approved, report_rejected, broadcast',
  `link` VARCHAR(255) DEFAULT NULL COMMENT 'رابط التوجيه الذكي داخل التطبيق',
  `is_read` TINYINT(1) DEFAULT 0 COMMENT '0: غير مقروء، 1: مقروء',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_user_read` (`user_id`, `is_read`),
  INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 3. برمجة الباك إند (PHP)

### أ) متى يتم إنشاء إشعار للمهندس؟ (Triggers)

ضَع هذا الكود داخل دوال الباك إند في ملفات `management.php` أو `api.php`:

#### 1. عند إسناد مهمة جديدة للمهندس أو تعديلها:

```php
// داخل دالة save_task أو work_plan_save
function notifyEngineerNewTask($engineerId, $taskId, $taskTitle, $siteName) {
    $title = "📋 مهمة عمل جديدة: {$taskTitle}";
    $msg = "تم تكليفك بمهمة عمل جديدة في موقع {$siteName}.";
    $link = "engineer/tasks.php?id={$taskId}";

    $stmt = db()->prepare("INSERT INTO notifications (user_id, title, message, type, link) VALUES (?, ?, ?, 'task', ?)");
    $stmt->execute([$engineerId, $title, $msg, $link]);
}
```

#### 2. عند مراجعة واعتماد أو رفض التقرير اليومي:

```php
// داخل دالة report_review
function notifyEngineerReportReviewed($engineerId, $reportId, $siteName, $decision, $adminNotes) {
    $isApproved = ($decision === 'approved');
    $title = $isApproved ? "✅ تم اعتماد تقريرك اليومي" : "⚠️ تم رفض تقريرك اليومي";
    $type = $isApproved ? "report_approved" : "report_rejected";
    $msg = "تقرير موقع {$siteName}: " . (!empty($adminNotes) ? $adminNotes : ($isApproved ? "تم الاعتماد بنجاح." : "يرجى مراجعة وتعديل التقرير."));
    $link = "engineer/reports.php?id={$reportId}";

    $stmt = db()->prepare("INSERT INTO notifications (user_id, title, message, type, link) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$engineerId, $title, $msg, $type, $link]);
}
```

#### 3. عند إصدار تعميم عام (Broadcast):

```php
function notifyAllEngineersBroadcast($title, $message, $link = null) {
    // جلب جميع المهندسين النشطين
    $engineers = db()->query("SELECT id FROM users WHERE role = 'engineer' AND is_active = 1")->fetchAll(PDO::FETCH_COLUMN);
    $stmt = db()->prepare("INSERT INTO notifications (user_id, title, message, type, link) VALUES (?, ?, ?, 'broadcast', ?)");
    foreach ($engineers as $engId) {
        $stmt->execute([$engId, "📢 تعميم: " . $title, $message, $link]);
    }
}
```

---

### ب) مسارات API الخاصة بالمهندس (API Routes)

أضف المسارات التالية لملف الراوت الخاص بالمهندس:

```php
// 1. جلب إشعارات المهندس
if ($apiRoute === 'notifications') {
    apiRequireMethod('GET');
    $engineerId = $currentAuthUser['id']; // معرف المهندس من التوكن

    $stmt = db()->prepare("
        SELECT id, title, message, type, link, is_read, created_at
        FROM notifications
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT 50
    ");
    $stmt->execute([$engineerId]);
    apiSuccess($stmt->fetchAll(PDO::FETCH_ASSOC));
}

// 2. تعليم إشعار كمقروء
if ($apiRoute === 'notification-read') {
    apiRequireMethod('POST');
    $input = json_decode(file_get_contents('php://input'), true);
    $notifId = $input['notification_id'] ?? 0;
    $engineerId = $currentAuthUser['id'];

    $stmt = db()->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
    $stmt->execute([$notifId, $engineerId]);
    apiSuccess(['status' => 'ok']);
}

// 3. تعليم كل الإشعارات كمقروءة
if ($apiRoute === 'notification-read-all') {
    apiRequireMethod('POST');
    $engineerId = $currentAuthUser['id'];

    $stmt = db()->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
    $stmt->execute([$engineerId]);
    apiSuccess(['status' => 'ok']);
}
```

---

## 4. الحل الأول: التحديث الصامت (Cascade Polling) — الموصى به

**فكرة العمل:**
بدلاً من الضغط اليدوي على Refresh، يقوم التطبيق بمراقبة الإشعارات كل 10 إلى 15 ثانية بصمت:

- إذا وصل للمهندس إشعار جديد يخص مهمة (`type == 'task'`)، يقوم التطبيق تلقائياً وبدون تدخل المهندس باستدعاء `tasksProvider.fetchTasks(silent: true)`.
- إذا كان الإشعار يخص اعتماد تقرير (`type == 'report_approved'`)، يقوم باستدعاء `reportsProvider.fetchReports(silent: true)`.
- يتم تحديث الشاشات أمام المهندس فوراً ومكان التمرير (Scroll) محفوظ تماماً وبدون مؤشر لودينغ مزعج!

---

## 5. الحل الثاني: الويب سوكيت (WebSockets & SSE)

إذا كان لديك خادم يدعم WebSockets (مثل Pusher أو Socket.io أو خادم Node.js وسيط):

### 1. باستخدام خدمة Pusher / Soketi:

في الباك إند:

```php
$pusher->trigger("engineer-{$engineerId}", 'new-notification', [
    'title' => $title,
    'message' => $msg,
    'link' => $link
]);
```

في Flutter (عبر حزمة `pusher_channels_flutter`):

```dart
pusher.subscribe(
  channelName: "engineer-${currentUserId}",
  onEvent: (event) {
    // 1. تشغيل صوت تنبيه
    // 2. تحديث قائمة الإشعارات والمهام فوراً
    notificationsProvider.fetchNotifications(silent: true);
    tasksProvider.fetchTasks(silent: true);
  },
);
```

### 2. باستخدام Server-Sent Events (SSE) عبر PHP العادي:

في PHP (`sse_notifications.php`):

```php
header('Content-Type: text/event-stream');
header('Cache-Control: no-cache');
header('Connection: keep-alive');

while (true) {
    // فحص ما إذا كان هناك إشعار غير مقروء حديث
    $notif = checkNewNotification($engineerId);
    if ($notif) {
        echo "data: " . json_encode($notif) . "\n\n";
        ob_flush();
        flush();
    }
    sleep(5);
}
```

---

## 6. الحل الثالث: أدوات التحديث اليدوي (Manual Refresh)

بالإضافة للتحديث التلقائي، يجب دائماً توفير خيار يدوي واضح للمهندس:

### 1. السحب للأسفل (Pull-To-Refresh):

```dart
RefreshIndicator(
  color: const Color(0xFF078DA5),
  onRefresh: () async {
    await Future.wait([
      tasksProvider.fetchTasks(),
      notificationsProvider.fetchNotifications(),
    ]);
  },
  child: ListView(...),
)
```

### 2. زر تحديث صريح في AppBar:

```dart
IconButton(
  icon: const Icon(Icons.refresh_rounded),
  tooltip: 'تحديث البيانات',
  onPressed: () {
    tasksProvider.fetchTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث البيانات'), duration: Duration(seconds: 1)),
    );
  },
)
```

---

## 7. كود تطبيق المهندس (Flutter Architecture)

### المودل (`lib/models/notification_model.dart`)

```dart
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.link,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      link: json['link']?.toString(),
      isRead: (json['is_read'] == 1 || json['is_read'] == true || json['is_read'] == '1'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      link: link,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
```

---

### المزوّد (`lib/providers/notifications_provider.dart`)

```dart
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationsProvider extends ChangeNotifier {
  final ApiService api;
  NotificationsProvider({required this.api});

  List<NotificationModel> _items = [];
  bool _isLoading = false;
  String? _error;
  int _lastUnreadCount = 0;

  List<NotificationModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> fetchNotifications({
    bool silent = false,
    void Function(NotificationModel latestItem)? onNewNotificationReceived,
  }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final res = await api.get('notifications');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['notifications'] ?? res['data'] ?? [];
      }

      final fetched = rawList
          .whereType<Map>()
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final currentUnread = fetched.where((n) => !n.isRead).length;

      // تحقق مما إذا كان هناك إشعار جديد وصل للتو
      if (currentUnread > _lastUnreadCount && fetched.isNotEmpty) {
        final latest = fetched.first;
        if (!latest.isRead && onNewNotificationReceived != null) {
          onNewNotificationReceived(latest);
        }
      }
      _lastUnreadCount = currentUnread;

      _items = fetched;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (!silent) {
        _error = 'تعذر جلب الإشعارات';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final idx = _items.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isRead: true);
      notifyListeners();
    }

    try {
      await api.post('notification-read', {'notification_id': notificationId});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    notifyListeners();

    try {
      await api.post('notification-read-all', {});
    } catch (_) {}
  }
}
```

---

### الأداة الموحدة للتحديث الدوري (`lib/widgets/auto_refresh_wrapper.dart`)

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class AutoRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Duration interval;

  const AutoRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.interval = const Duration(seconds: 12),
  });

  @override
  State<AutoRefreshWrapper> createState() => _AutoRefreshWrapperState();
}

class _AutoRefreshWrapperState extends State<AutoRefreshWrapper> with WidgetsBindingObserver {
  Timer? _timer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) => _execute());
  }

  Future<void> _execute() async {
    if (_isRefreshing || !mounted) return;
    _isRefreshing = true;
    try {
      await widget.onRefresh();
    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _execute();
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

---

### شارة العداد في الـ AppBar (`NotificationBadge`)

```dart
class NotificationBadgeButton extends StatelessWidget {
  final VoidCallback onTap;

  const NotificationBadgeButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationsProvider>().unreadCount;

    return IconButton(
      tooltip: 'الإشعارات والتنبيهات',
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, size: 26),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFBD3F42), // أحمر أنيق
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  unreadCount > 99 ? '+99' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

### شاشة الإشعارات والتوجيه الذكي (`lib/screens/notifications_screen.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../widgets/auto_refresh_wrapper.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _onNotificationTapped(BuildContext context, NotificationModel item) async {
    final prov = context.read<NotificationsProvider>();
    if (!item.isRead) {
      prov.markAsRead(item.id);
    }

    final link = item.link;
    if (link == null || link.isEmpty) return;

    // استخراج المعرف من الرابط
    final uri = Uri.tryParse('https://vehiclegate.ghusun.net/$link');
    final query = uri?.queryParameters ?? {};
    final id = int.tryParse(query['id'] ?? '');

    // التوجيه للشاشة المعنية
    if (link.contains('tasks') || link.contains('work_plans')) {
      // افتح شاشة المهمة المحددة
      // Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: id)));
    } else if (link.contains('reports')) {
      // افتح شاشة التقرير المحددة
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailScreen(reportId: id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationsProvider>();

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 10),
      onRefresh: () => prov.fetchNotifications(silent: true),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التنبيهات والإشعارات'),
          actions: [
            if (prov.unreadCount > 0)
              TextButton.icon(
                icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
                label: const Text('قراءة الكل', style: TextStyle(color: Colors.white, fontSize: 13)),
                onPressed: () => prov.markAllAsRead(),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => prov.fetchNotifications(),
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('لا توجد إشعارات حالياً', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: prov.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = prov.items[index];
                        return _NotificationCard(
                          item: item,
                          onTap: () => _onNotificationTapped(context, item),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF078DA5); // أزرق افتراضي
    IconData iconData = Icons.info_outline;

    if (item.type.contains('approved')) {
      cardColor = const Color(0xFF13805D); // أخضر نجاح
      iconData = Icons.check_circle_rounded;
    } else if (item.type.contains('rejected')) {
      cardColor = const Color(0xFFBD3F42); // أحمر رفض
      iconData = Icons.cancel_rounded;
    } else if (item.type.contains('task')) {
      cardColor = const Color(0xFF078DA5); // سماوي مهام
      iconData = Icons.assignment_rounded;
    } else if (item.type.contains('broadcast')) {
      cardColor = const Color(0xFFB76B08); // برتقالي تعميم
      iconData = Icons.campaign_rounded;
    }

    return Card(
      elevation: item.isRead ? 0.5 : 2,
      color: item.isRead ? Colors.white : cardColor.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: item.isRead ? Colors.grey.shade200 : cardColor.withOpacity(0.4),
          width: item.isRead ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cardColor.withOpacity(0.12),
                child: Icon(iconData, color: cardColor, size: 22),
              ),
              const SizedBox(width: 12),
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
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: const Color(0xFF102B3F),
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')} · ${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 8. التنبيهات الصوتية والمحلية (Audio & In-App Alerts)

لإشعار المهندس صوتياً عند وصول مهمة جديدة وهو داخل التطبيق:

1. أضف حزمة `audioplayers` أو `flutter_local_notifications` في `pubspec.yaml`:
   ```yaml
   dependencies:
     audioplayers: ^6.0.0
   ```
2. عند اكتشاف إشعار جديد في الـ `NotificationsProvider`:
   ```dart
   final player = AudioPlayer();
   await player.play(AssetSource('sounds/notification.mp3'));
   ```
3. إظهار SnackBar علوي فوري:
   ```dart
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
       behavior: SnackBarBehavior.floating,
       backgroundColor: const Color(0xFF102B3F),
       content: Text('🔔 ${latestItem.title}: ${latestItem.message}'),
       action: SnackBarAction(
         label: 'فتح',
         textColor: Colors.amber,
         onPressed: () => _onNotificationTapped(context, latestItem),
       ),
     ),
   );
   ```

---

## 🏁 خلاصة تفعيل النظام

1. نفّذ جدول الـ SQL في قاعدة البيانات.
2. ضع كود الـ Triggers في الـ PHP عند حفظ المهام واعتماد التقارير.
3. انقل الأكواد إلى مشروع المهندس (Flutter).
4. بمجرد عمل ذلك، سيصبح التطبيق محدثاً تلقائياً كل 10 ثوانٍ، وتظهر الأرقام الحمراء فوراً، ويصل المهندس لما يريده بضغطة زر واحدة!
