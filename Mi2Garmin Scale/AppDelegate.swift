//
//  AppDelegate.swift
//  Mi2Garmin Scale
//
//  Created by Alexey Panfilov on 19.02.2024.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Запрос разрешения на отправку уведомлений
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            // Проверьте, предоставил ли пользователь разрешение
            if granted {
                print("Разрешение на уведомления получено")
            } else {
                print("Разрешение на уведомления не получено")
            }
        }
        return true
    }
}
