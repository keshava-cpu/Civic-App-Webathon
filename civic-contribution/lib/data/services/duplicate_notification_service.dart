import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Single responsibility: show a local device notification when a
/// duplicate issue is detected during the report flow.
class DuplicateNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    _initialized = true;
  }

  /// Shows a notification telling the user their image matches an already-posted
  /// issue and will count as an upvote if submitted.
  Future<void> showDuplicateIssueNotification({
    required String existingIssueId,
    String? existingDescription,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'duplicate_issues',
      'Duplicate Issue Alerts',
      channelDescription:
          'Alerts when a photo you are about to post matches an existing issue',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      existingIssueId.hashCode & 0x7FFFFFFF,
      'Issue already reported',
      'The issue you are going to post is already posted and will be '
          'taken as an upvote if posted.',
      details,
      payload: existingIssueId,
    );
  }
}
