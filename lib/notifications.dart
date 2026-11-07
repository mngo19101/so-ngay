import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'logic.dart';

/// Thông báo cục bộ (không dùng push server).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(settings: const InitializationSettings(iOS: ios, android: android));
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
      final and = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (and != null) return await and.requestNotificationsPermission() ?? false;
    } catch (e) {
      debugPrint('permission: $e');
    }
    return false;
  }

  NotificationDetails _details(bool sound) => NotificationDetails(
        iOS: DarwinNotificationDetails(
            presentAlert: true, presentBanner: true, presentList: true, presentBadge: true, presentSound: sound),
        android: AndroidNotificationDetails('songay', 'Sổ Ngày',
            channelDescription: 'Nhắc ngày đặc biệt và lịch', importance: Importance.high, playSound: sound),
      );

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  Future<void> schedule(List<Planned> plan, {required bool sound}) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      var id = 1;
      for (final p in plan) {
        await _plugin.zonedSchedule(
          id: id++,
          title: p.title,
          body: p.body,
          scheduledDate: tz.TZDateTime.from(p.when, tz.local),
          notificationDetails: _details(sound),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: switch (p.repeat) {
            'daily' => DateTimeComponents.time,
            'weekly' => DateTimeComponents.dayOfWeekAndTime,
            'yearly' => DateTimeComponents.dateAndTime,
            _ => null,
          },
        );
      }
    } catch (e) {
      debugPrint('schedule failed: $e');
    }
  }

  /// Trả về false nếu chưa được cấp quyền hoặc gửi lỗi.
  Future<bool> showNow(String title, String body, {required bool sound}) async {
    if (!await requestPermission()) return false;
    try {
      await _plugin.show(id: 0, title: title, body: body, notificationDetails: _details(sound));
      return true;
    } catch (e) {
      debugPrint('show failed: $e');
      return false;
    }
  }

  /// Thông báo thử đến sau [delay], để kiểm tra khi đã thoát app hoặc khoá máy.
  Future<bool> showLater(String title, String body, Duration delay, {required bool sound}) async {
    if (!await requestPermission()) return false;
    try {
      await _plugin.zonedSchedule(
        id: 9999,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
        notificationDetails: _details(sound),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      debugPrint('showLater failed: $e');
      return false;
    }
  }
}
