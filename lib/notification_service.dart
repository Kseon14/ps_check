import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'model.dart';

const String applicationName = "Game Checker";

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

    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      //onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: null);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
    tz.initializeTimeZones();
  }

  // Future selectNotification(String payload) async {
  //   UserBirthday userBirthday = getUserBirthdayFromPayload(payload);
  //   cancelNotificationForBirthday(userBirthday);
  //   scheduleNotificationForBirthday(userBirthday, "${userBirthday.name} has an upcoming birthday!");
  // }

  Future selectNotification(String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
  }

  void showNotification(Data data) async {
    debugPrint('notification payload: start');
    String text = data.productRetrieve!.name! + " have new price: " +
        data.productRetrieve!.webctas![0].price!.discountedPrice!;
    await flutterLocalNotificationsPlugin.show(
        data.hashCode,
        "Price Drop",
        text,
        const NotificationDetails(
            android: AndroidNotificationDetails(channel_id,
                applicationName,
                ),
          iOS: const
            IOSNotificationDetails(
            presentAlert: false,  // Present an alert when the notification is displayed and the application is in the foreground (only from iOS 10 onwards)
            presentBadge: false,  // Present the badge number when the notification is displayed and the application is in the foreground (only from iOS 10 onwards)
            presentSound: true,  // Play a sound when the notification is displayed and the application is in the foreground (only from iOS 10 onwards)// Specifics the file path to play (only from iOS 10 onwards)
            //badgeNumber: 1, // The application's icon badge number
            //subtitle: "new discount", //Secondary description  (only from iOS 10 onwards)
            threadIdentifier: "game_checker"
          )

        ),
        payload: null
    );
  }

  void cancelNotificationForBirthday(Data data) async {
    await flutterLocalNotificationsPlugin.cancel(data.hashCode);
  }

  void cancelAllNotifications() async {
    flutterLocalNotificationsPlugin.cancelAll();
  }

  void handleApplicationWasLaunchedFromNotification() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
    await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  }

  Data getGaFromJson(String payload) {
    Map<String, dynamic> json = jsonDecode(payload);
    return Data.fromJsonInt(json);
  }

  Future<bool> _wasApplicationLaunchedFromNotification() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
    await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    return notificationAppLaunchDetails!.didNotificationLaunchApp;
  }

  Future<void> _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}