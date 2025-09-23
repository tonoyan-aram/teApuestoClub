import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:apuesto_club/main.dart'; // Import the global plugin instance
import 'package:apuesto_club/models/reminder_settings.dart';

class NotificationService {
  NotificationService() {
    tzdata.initializeTimeZones();
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Ensure the scheduledDate is in the local timezone
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    // Schedule notification only if it's in the future
    if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('Scheduled date is in the past, not scheduling notification.');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'event_channel_id', // id
          'Event Reminders', // name
          channelDescription: 'Notifications for upcoming sports events',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
        );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime, // Updated from forWholeDay
      payload: payload,
    );
    debugPrint('Notification scheduled for ID: $id at $tzScheduledDate');
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('Notification with ID $id cancelled.');
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('All notifications cancelled.');
  }

  // Schedule multiple reminders for an event
  Future<void> scheduleReminders({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    required List<Reminder> reminders,
    String? payload,
  }) async {
    for (final reminder in reminders) {
      if (!reminder.isEnabled) continue;

      final reminderDate = eventDate.subtract(reminder.getDuration());
      
      // Only schedule if reminder is in the future
      if (reminderDate.isBefore(DateTime.now())) continue;

      final reminderId = _generateReminderId(eventId, reminder.id);
      final reminderTitle = reminder.customMessage ?? 'Event Reminder';
      final reminderBody = '$eventTitle - ${reminder.getDescription()}';

      await scheduleNotification(
        id: reminderId,
        title: reminderTitle,
        body: reminderBody,
        scheduledDate: reminderDate,
        payload: payload,
      );
    }
  }

  // Cancel all reminders for an event
  Future<void> cancelEventReminders(String eventId, List<Reminder> reminders) async {
    for (final reminder in reminders) {
      final reminderId = _generateReminderId(eventId, reminder.id);
      await cancelNotification(reminderId);
    }
  }

  // Generate unique ID for reminder
  int _generateReminderId(String eventId, String reminderId) {
    return '${eventId}_$reminderId'.hashCode;
  }

  // Schedule smart reminders based on event category
  Future<void> scheduleSmartReminders({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    required String category,
    String? payload,
  }) async {
    final reminders = ReminderTemplates.getRemindersForCategory(category);
    await scheduleReminders(
      eventId: eventId,
      eventTitle: eventTitle,
      eventDate: eventDate,
      reminders: reminders,
      payload: payload,
    );
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Check if notification is scheduled
  Future<bool> isNotificationScheduled(int id) async {
    final pending = await getPendingNotifications();
    return pending.any((notification) => notification.id == id);
  }
}
