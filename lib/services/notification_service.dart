import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/course.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'course_reminders';
  static const String _channelName = 'Ders Hatırlatıcıları';
  static const String _channelDescription =
      'Ders başlamadan önce gönderilen hatırlatıcılar';

  static bool _initialized = false;

  static Future<String?> initialize() async {
    if (_initialized) return null;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          'Bildirime tıklandı. Course ID: ${response.payload ?? ''}',
        );
      },
    );

    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
    return null;
  }

  static Future<void> scheduleCourseNotification(
    Course course, {
    required bool isEnglish,
  }) async {
    await initialize();

    if (course.id.isEmpty) return;

    final weekday = _weekdayNumber(course.day);
    final timeParts = course.startTime.split(':');

    if (weekday == null || timeParts.length != 2) return;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final daysUntilCourse = (weekday - now.weekday + 7) % 7;

    var courseDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilCourse,
      hour,
      minute,
    );

    var notificationDate =
        courseDate.subtract(const Duration(minutes: 30));

    if (!notificationDate.isAfter(now)) {
      courseDate = courseDate.add(const Duration(days: 7));
      notificationDate =
          courseDate.subtract(const Duration(minutes: 30));
    }

    final title =
        isEnglish ? 'Course Reminder' : 'Ders Hatırlatıcı';

    final roomText = course.room.trim().isEmpty
        ? ''
        : isEnglish
            ? '\nRoom: ${course.room}'
            : '\nSınıf: ${course.room}';

    final body = isEnglish
        ? '${course.title} starts in 30 minutes.$roomText'
        : '${course.title} dersin 30 dakika sonra başlıyor.$roomText';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final beforeNotificationId =
        _notificationId('${course.id}:before');
    final startNotificationId =
        _notificationId('${course.id}:start');

    await _notifications.cancel(id: beforeNotificationId);
    await _notifications.cancel(id: startNotificationId);

    await _notifications.zonedSchedule(
      id: beforeNotificationId,
      title: title,
      body: body,
      scheduledDate: notificationDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: course.id,
    );

    final startBody = isEnglish
        ? '${course.title} is starting now.$roomText'
        : '${course.title} dersin şimdi başlıyor.$roomText';

    await _notifications.zonedSchedule(
      id: startNotificationId,
      title: title,
      body: startBody,
      scheduledDate: courseDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: course.id,
    );

    debugPrint(
      '30 dk önce bildirimi: ${course.title} -> $notificationDate',
    );
    debugPrint(
      'Ders saati bildirimi: ${course.title} -> $courseDate',
    );
  }

  static Future<void> cancelCourseNotification(String courseId) async {
    if (courseId.isEmpty) return;

    await initialize();
    await _notifications.cancel(
      id: _notificationId('$courseId:before'),
    );
    await _notifications.cancel(
      id: _notificationId('$courseId:start'),
    );
  }

  static Future<void> syncCourseNotifications(
    List<Course> courses, {
    required bool isEnglish,
  }) async {
    await initialize();

    await _notifications.cancelAll();

    for (final course in courses) {
      await scheduleCourseNotification(
        course,
        isEnglish: isEnglish,
      );
    }
  }

  static int _notificationId(String courseId) {
    const int fnvOffset = 0x811c9dc5;
    const int fnvPrime = 0x01000193;

    var hash = fnvOffset;

    for (final codeUnit in courseId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0x7fffffff;
    }

    return hash;
  }

  static int? _weekdayNumber(String day) {
    switch (day.trim().toLowerCase()) {
      case 'pazartesi':
      case 'monday':
        return DateTime.monday;
      case 'salı':
      case 'sali':
      case 'tuesday':
        return DateTime.tuesday;
      case 'çarşamba':
      case 'carsamba':
      case 'wednesday':
        return DateTime.wednesday;
      case 'perşembe':
      case 'persembe':
      case 'thursday':
        return DateTime.thursday;
      case 'cuma':
      case 'friday':
        return DateTime.friday;
      case 'cumartesi':
      case 'saturday':
        return DateTime.saturday;
      case 'pazar':
      case 'sunday':
        return DateTime.sunday;
      default:
        return null;
    }
  }
}
