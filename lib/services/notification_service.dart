import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const String kNotificationChannelId = 'maxlond_urgent_channel';
const String kNotificationChannelName = 'تنبيهات ماكسلوند العاجلة';
const String kNotificationChannelDesc = 'إشعارات المهام والتقارير الميدانية';
const int kForegroundServiceId = 999;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        await localNotifier.setup(appName: 'Maxlond Management');
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: initAndroid);

        await flutterLocalNotificationsPlugin.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            handleNotificationLink(response.payload);
          },
        );

        const channel = AndroidNotificationChannel(
          kNotificationChannelId,
          kNotificationChannelName,
          description: kNotificationChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        final service = FlutterBackgroundService();
        await service.configure(
          androidConfiguration: AndroidConfiguration(
            onStart: backgroundNotificationHandler,
            autoStart: true,
            isForegroundMode: true,
            notificationChannelId: kNotificationChannelId,
            initialNotificationTitle: 'ماكسلوند للإدارة',
            initialNotificationContent: 'خدمة التنبيهات المباشرة تعمل بالخلفية',
            foregroundServiceNotificationId: kForegroundServiceId,
          ),
          iosConfiguration: IosConfiguration(),
        );

        await service.startService();
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> showWindowsNotification({
    required String title,
    required String message,
    String? link,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
    try {
      final notif = LocalNotification(
        title: title,
        body: message,
      );
      notif.onClick = () {
        handleNotificationLink(link);
      };
      await notif.show();
    } catch (_) {}
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String message,
    String? link,
  }) async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.windows) {
      await showWindowsNotification(title: title, message: message, link: link);
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            kNotificationChannelId,
            kNotificationChannelName,
            channelDescription: kNotificationChannelDesc,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(
              message,
              contentTitle: title,
              summaryText: 'ماكسلوند',
            ),
          ),
        );

        await flutterLocalNotificationsPlugin.show(
          id: id,
          title: title,
          body: message,
          notificationDetails: details,
          payload: link,
        );
      } catch (_) {}
    }
  }

  static void handleNotificationLink(String? link) {
    if (link == null || link.isEmpty) return;
    // deep linking
  }
}

@pragma('vm:entry-point')
void backgroundNotificationHandler(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  Timer.periodic(const Duration(seconds: 25), (timer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final lastId = prefs.getInt('last_seen_notification_id') ?? 0;

      if (token.isEmpty) return;

      final url = Uri.parse('https://vehiclegate.ghusun.net/api/management.php?route=notifications');
      final res = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) Maxlond/1.0',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          list = data['notifications'] ?? data['data'] ?? data['items'] ?? [];
        }

        if (list.isNotEmpty) {
          final latest = list.first;
          final int curId = (latest['id'] is num)
              ? (latest['id'] as num).toInt()
              : int.tryParse(latest['id']?.toString() ?? '0') ?? 0;

          if (curId > lastId) {
            await prefs.setInt('last_seen_notification_id', curId);

            final String title = latest['title']?.toString() ?? 'إشعار جديد';
            final String msg = latest['message']?.toString() ?? '';
            final String? link = latest['link']?.toString();

            final details = NotificationDetails(
              android: AndroidNotificationDetails(
                kNotificationChannelId,
                kNotificationChannelName,
                channelDescription: kNotificationChannelDesc,
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                styleInformation: BigTextStyleInformation(
                  msg,
                  contentTitle: title,
                  summaryText: 'ماكسلوند',
                ),
              ),
            );

            await flutterLocalNotificationsPlugin.show(
              id: curId,
              title: title,
              body: msg,
              notificationDetails: details,
              payload: link,
            );
          }
        }
      }
    } catch (_) {}
  });
}