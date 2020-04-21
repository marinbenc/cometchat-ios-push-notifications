//
//  AppDelegate.swift
//  CometChat
//
//  Created by Marin Benčević on 01/08/2019.
//  Copyright © 2019 marinbenc. All rights reserved.
//

import UIKit
import Firebase
import CometChatPro

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Initialize CometChat when the app launches
    ChatService.initialize()
    
    FirebaseApp.configure()
    UNUserNotificationCenter.current().delegate = self
    
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.badge, .sound, .alert],
      completionHandler: {granted, _ in
        guard granted else { return }
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
    })

    return true
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Cannot register for notifications: \(error)")
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // Print message ID.
    if let messageID = userInfo["gcm.message_id"] {
      print("Message ID: \(messageID)")
    }

    // Print full message.
    print(userInfo)
  }
  
  
}


extension AppDelegate: UNUserNotificationCenterDelegate {
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Grab the message object
    guard
      let rawMessage = notification.request.content.userInfo["message"] as? String,
      let messageData = rawMessage.data(using: .utf8),
      let messageJSON = try? JSONSerialization.jsonObject(with: messageData, options: []) as? [String: Any],
      let message = CometChat.processMessage(messageJSON).0
    else {
      return
    }
    
    let notificationSender = message.senderUid
    
    // Get the current top view controller
    let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    
    if let navigationController = keyWindow?.rootViewController as? UINavigationController,
      let chatViewController = navigationController.topViewController as? ChatViewController {
      
      let currentReceiver = chatViewController.receiver.id
      if currentReceiver == notificationSender {
        // Silence ntoification if currently chatting with the sender
        completionHandler([])
        return
      }
    }

    // Otherwise, display notification normally
    completionHandler([.sound, .alert])
  }

}
