//
//  Mi2Garmin_ScaleApp.swift
//  Mi2Garmin Scale
//
//  Created by Alexey Panfilov on 16.02.2024.
//

import SwiftUI

@main
struct Mi2Garmin_ScaleApp: App {
    // Подключение AppDelegate
     @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
