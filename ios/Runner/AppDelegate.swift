import UIKit
import Firebase
import Flutter
import workmanager_apple

import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

  FirebaseApp.configure()
    // This is required to make any communication available in the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }

    UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*12*60))

    application.applicationIconBadgeNumber = 0 // For Clear Badge Counts
    let center = UNUserNotificationCenter.current()
    center.removeAllDeliveredNotifications() // To remove all delivered notifications
    center.removeAllPendingNotificationRequests()

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// @UIApplicationMain
// @objc class AppDelegate: FlutterAppDelegate {
//
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//
//   FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
//       GeneratedPluginRegistrant.register(with: registry)
//     }
//
//     GeneratedPluginRegistrant.register(with: self)
//     UNUserNotificationCenter.current().delegate = self
//
//             WorkmanagerPlugin.setPluginRegistrantCallback { registry in
//                 // registry in this case is the FlutterEngine that is created in Workmanager's performFetchWithCompletionHandler
//                 // This will make other plugins available during a background fetch
//                 GeneratedPluginRegistrant.register(with: registry)
//
//             }
//              application.applicationIconBadgeNumber = 0 // For Clear Badge Counts
//                     let center = UNUserNotificationCenter.current()
//                     center.removeAllDeliveredNotifications() // To remove all delivered notifications
//                     center.removeAllPendingNotificationRequests()
//
//
// if #available(iOS 10.0, *) {
//   UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
// }
//
// let center = UNUserNotificationCenter.current()
// center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//     if let error = error {
//         // Handle the error here.
//     }
//     // Enable or disable features based on the authorization.
// }
// return super.application(application, didFinishLaunchingWithOptions: launchOptions)
// }
// }
