import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class ReminderTime {
  const ReminderTime({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;
}

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const int _dailyReminderId = 1001;
  static const String _enabledKey = 'daily_reminder_enabled';
  static const String _hourKey = 'daily_reminder_hour';
  static const String _minuteKey = 'daily_reminder_minute';
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'daily_reminders',
    'التذكير اليومي',
    description: 'تذكير يومي للعودة إلى مهام ShadowDev',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _initialized = true;
  }

  Future<ReminderTime> getReminderTime() async {
    final enabled = await _storage.read(key: _enabledKey) == 'true';
    final hour = int.tryParse(await _storage.read(key: _hourKey) ?? '') ?? 20;
    final minute =
        int.tryParse(await _storage.read(key: _minuteKey) ?? '') ?? 0;
    return ReminderTime(enabled: enabled, hour: hour, minute: minute);
  }

  Future<bool> enableDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await initialize();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final permissionGranted =
        await androidPlugin?.requestNotificationsPermission();
    if (permissionGranted != true) return false;

    await _scheduleDailyReminder(hour: hour, minute: minute);
    await _storage.write(key: _enabledKey, value: 'true');
    await _storage.write(key: _hourKey, value: hour.toString());
    await _storage.write(key: _minuteKey, value: minute.toString());
    return true;
  }

  Future<void> disableDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
    await _storage.write(key: _enabledKey, value: 'false');
  }

  Future<void> restoreDailyReminder() async {
    final reminder = await getReminderTime();
    if (!reminder.enabled) return;
    await _scheduleDailyReminder(
      hour: reminder.hour,
      minute: reminder.minute,
    );
  }

  Future<void> _scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduledDate = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduledDate.isAfter(now)) {
      final nextDay = DateTime(now.year, now.month, now.day + 1);
      scheduledDate = timezone.TZDateTime(
        timezone.local,
        nextDay.year,
        nextDay.month,
        nextDay.day,
        hour,
        minute,
      );
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'مهمتك اليومية بانتظارك',
      'ارجع إلى ShadowDev وحافظ على سلسلة تقدمك.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'التذكير اليومي',
          channelDescription: 'تذكير يومي للعودة إلى مهام ShadowDev',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF00F0FF),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
