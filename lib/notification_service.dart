import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'model.dart';

const String applicationName = "Game Checker";

void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  debugPrint('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    debugPrint(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  static const channel_id = "game_checker";

  Future<void> init() async {
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      //onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final StreamController<String?> selectNotificationStream =
        StreamController<String?>.broadcast();

    const String navigationActionId = 'id_3';

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: null, iOS: initializationSettingsIOS, macOS: null);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            selectNotificationStream.add(notificationResponse.payload);
            break;
          case NotificationResponseType.selectedNotificationAction:
            if (notificationResponse.actionId == navigationActionId) {
              selectNotificationStream.add(notificationResponse.payload);
            }
            break;
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    tz.initializeTimeZones();
  }

  Future selectNotification(String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
  }

  void showNotification(Data data) async {
    debugPrint('notification payload: start');
    var product = data.products.first;
    String text =
        product.name! + " has new price: " + product.getDiscountedPrice();
    await flutterLocalNotificationsPlugin.show(
        data.hashCode,
        "Price Drop",
        text,
        const NotificationDetails(
            android: AndroidNotificationDetails(
              channel_id,
              applicationName,
            ),
            iOS: const DarwinNotificationDetails(
                presentAlert: false,
                // Present an alert when the notification is displayed and the application is in the foreground (only from iOS 10 onwards)
                presentBadge: false,
                // Present the badge number when the notification is displayed and the application is in the foreground (only from iOS 10 onwards)
                presentSound: true,
                // Play a sound when the notification is displayed and the application is in the foreground (only from iOS 10 onwards)// Specifics the file path to play (only from iOS 10 onwards)
                //badgeNumber: 1, // The application's icon badge number
                //subtitle: "new discount", //Secondary description  (only from iOS 10 onwards)
                threadIdentifier: "game_checker")),
        payload: null);
  }

  void cancelAllNotifications() async {
    flutterLocalNotificationsPlugin.cancelAll();
  }
}
