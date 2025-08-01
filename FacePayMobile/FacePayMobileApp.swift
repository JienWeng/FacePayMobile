//
//  FacePayMobileApp.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 31/07/2025.
//

import SwiftUI
import UserNotifications

@main
struct FacePayMobileApp: App {
    init() {
        // Request notification permissions on app launch
        NotificationManager.shared.requestPermission()
        NotificationManager.shared.setupNotificationActions()
    }
    
    var body: some Scene {
        WindowGroup {
            LandingView()
        }
    }
}
