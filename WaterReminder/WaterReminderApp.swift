//
//  WaterReminderApp.swift
//  WaterReminder
//
//  Created by 程星涵 on 24/2/2025.
//

import SwiftUI
import UserNotifications

@main
struct WaterReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // 清除角标
        application.applicationIconBadgeNumber = 0
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // 只使用 applicationIconBadgeNumber 来清除角标
        application.applicationIconBadgeNumber = 0
    }
    
    // 当应用在前台时显示通知，并包含所有选项
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 在 iOS 14 及以上版本使用这些选项
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            // 在低版本 iOS 中使用这些选项
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // 处理用户点击通知的响应
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        // 只使用 applicationIconBadgeNumber 来清除角标
        UIApplication.shared.applicationIconBadgeNumber = 0
        completionHandler()
    }
}
