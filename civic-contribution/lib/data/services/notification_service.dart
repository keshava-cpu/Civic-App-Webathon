import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    _initialized = true;
  }

  Future<void> showNearbyIssueNotification({
    required String issueId,
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'nearby_issues',
      'Nearby Issues',
      channelDescription: 'Notifications for resolved issues near you to verify',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      issueId.hashCode,
      title,
      body,
      details,
      payload: issueId,
    );
  }

  Future<void> showVerificationCompleteNotification(String issueId) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'verifications',
      'Verifications',
      channelDescription: 'Issue verification status updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      issueId.hashCode + 1000,
      'Issue Verified!',
      'An issue you reported has been verified by the community.',
      details,
      payload: issueId,
    );
  }
}
