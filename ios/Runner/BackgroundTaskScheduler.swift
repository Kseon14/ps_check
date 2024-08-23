// // BackgroundTaskScheduler.swift
//
// import Foundation
// import BackgroundTasks
//
// class BackgroundTaskScheduler {
//     static let shared = BackgroundTaskScheduler()
//
//     private init() {
//         registerBackgroundTask()
//     }
//
//     private func registerBackgroundTask() {
//         let identifier = "com.psCheck.backgroundTaskFetch"
//         BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
//             self.handleBackgroundTask(task: task as! BGProcessingTask)
//         }
//
//         // Schedule the background task to run twice a day
//         let request = BGProcessingTaskRequest(identifier: identifier)
//         request.requiresNetworkConnectivity = false
//         request.requiresExternalPower = false
//
//         let interval = TimeInterval(12 * 60 * 60) // 12 hours in seconds
//         request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
//
//         do {
//             try BGTaskScheduler.shared.submit(request)
//         } catch {
//             print("Unable to schedule background task: \(error)")
//         }
//     }
//
//     private func handleBackgroundTask(task: BGProcessingTask) {
//         // Perform your background task logic here
//         // Call Dart method using platform channels
//         // Example:
//         FlutterBackgroundChannel.invokeMethod("callbackDispatcher", arguments: nil)
//
//         task.setTaskCompleted(success: true)
//     }
// }
