import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../screens/tasks/task_details_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background FCM message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'task_manager_high';
  static const String channelName = 'Task Manager';
  static const String channelDescription =
      'High priority notifications for new and updated tasks.';

  String? _pendingTaskId;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('ic_stat_task');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    await _createAndroidChannel();
    await _requestPermissions();
    await _registerToken();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageTap(initialMessage);
    }

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _openFromPayload(payload);
      }
    }
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _createAndroidChannel() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
      ),
    );
  }

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('FCM token refreshed: $newToken');
      });
    } catch (error) {
      debugPrint('FCM token error: $error');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final dataTitle = message.data['title'];
    final dataBody = message.data['body'];
    final title =
        notification?.title ?? (dataTitle is String ? dataTitle : 'New Task');
    final body =
        notification?.body ??
        (dataBody is String ? dataBody : 'You have a new task.');

    await showLocalNotification(
      title: title,
      body: body,
      taskId: _taskIdFromMessage(message),
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? taskId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_stat_task',
      colorized: false,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(<String, dynamic>{'type': 'task', 'taskId': taskId}),
    );
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _openFromPayload(payload);
    }
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    final taskId = _taskIdFromMessage(message);
    if (taskId == null || taskId.isEmpty) {
      _openTaskList();
      return;
    }

    _openTask(taskId);
  }

  void _openFromPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final taskId = decoded['taskId'] as String?;
        if (taskId != null && taskId.isNotEmpty) {
          _openTask(taskId);
        } else {
          _openTaskList();
        }
        return;
      }
    } catch (_) {
      // Some callers may pass a plain task ID instead of a JSON payload.
    }

    if (payload.isNotEmpty) {
      _openTask(payload);
    } else {
      _openTaskList();
    }
  }

  String? _taskIdFromMessage(RemoteMessage message) {
    final value = message.data['taskId'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  void _openTaskList() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    navigator.popUntil((route) => route.isFirst);
  }

  void _openTask(String taskId) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingTaskId = taskId;
      return;
    }

    navigator.popUntil((route) => route.isFirst);
    navigator.pushNamed(TaskDetailsScreen.routeName, arguments: taskId);
  }

  String? consumePendingTaskId() {
    final taskId = _pendingTaskId;
    _pendingTaskId = null;
    return taskId;
  }
}
