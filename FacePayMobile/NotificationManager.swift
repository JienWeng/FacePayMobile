//
//  NotificationManager.swift
//  FacePayMobile
//
//  Created by Lai Jien Weng on 01/08/2025.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func scheduleCardBindingNotification(cardType: String, cardNumber: String, userName: String, completion: @escaping (Bool) -> Void) {
        let content = UNMutableNotificationContent()
        
        // Customize notification based on card provider
        switch cardType.lowercased() {
        case "visa":
            content.title = "Visa Card Binding Request"
            content.body = "Do you want to bind your Visa card ending in \(String(cardNumber.suffix(4))) to \(userName)'s FacePay account?"
        case "mastercard":
            content.title = "Mastercard Binding Request"
            content.body = "Do you want to bind your Mastercard ending in \(String(cardNumber.suffix(4))) to \(userName)'s FacePay account?"
        case "american express":
            content.title = "American Express Binding Request"
            content.body = "Do you want to bind your Amex card ending in \(String(cardNumber.suffix(4))) to \(userName)'s FacePay account?"
        default:
            content.title = "Card Binding Request"
            content.body = "Do you want to bind your card ending in \(String(cardNumber.suffix(4))) to \(userName)'s FacePay account?"
        }
        
        content.sound = .default
        content.categoryIdentifier = "CARD_BINDING"
        
        // Add action buttons
        let confirmAction = UNNotificationAction(
            identifier: "CONFIRM_BINDING",
            title: "Yes, Bind Card",
            options: []
        )
        
        let denyAction = UNNotificationAction(
            identifier: "DENY_BINDING",
            title: "Cancel",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "CARD_BINDING",
            actions: [confirmAction, denyAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        // Schedule notification to appear immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "card_binding_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if error == nil {
                    completion(true)
                } else {
                    print("Failed to schedule notification: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                }
            }
        }
    }
    
    func setupNotificationActions() {
        // This will be called when the app receives notification responses
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "CONFIRM_BINDING":
            NotificationCenter.default.post(name: .cardBindingConfirmed, object: nil)
        case "DENY_BINDING":
            NotificationCenter.default.post(name: .cardBindingDenied, object: nil)
        default:
            break
        }
        
        completionHandler()
    }
}

// Notification names for communication between notification and app
extension Notification.Name {
    static let cardBindingConfirmed = Notification.Name("cardBindingConfirmed")
    static let cardBindingDenied = Notification.Name("cardBindingDenied")
}
