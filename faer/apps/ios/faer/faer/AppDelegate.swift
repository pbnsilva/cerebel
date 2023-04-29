//
//  AppDelegate.swift
//  faer
//
//  Created by pluto on 15.08.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import os.log
import AVFoundation
import Firebase
import FirebaseMessaging
import FacebookCore
import UserNotifications

class StyleGuide {
    
    enum font: String {
            case headline = "Montserrat-Bold"
            case body = "OpenSans-Regular"
            case icon = "FontAwesome5FreeSolid"
            case medium = "Montserrat-Medium"
            case regular = "Montserrat-Regular"
            case semiBold = "Montserrat-SemiBold"
    }
    
    enum icon: String {
        case heart = ""
        case back = ""
        case wallet = ""
        case coin = ""
        case marker = ""
        case shop = ""
    }
    
    static let fontRegular = "Montserrat-Regular"
    static let fontMedium = "Montserrat-Medium"
    static let fontBold = "Montserrat-Bold"
    static let fontSemiBold = "Montserrat-SemiBold"
    static let fontBody = "OpenSans-Regular"
    static let fontIcon = "FontAwesome5FreeSolid"
    
    static let fontHeadlineSize:CGFloat = 24
    static let fontMediumSize:CGFloat = 18
    static let fontCopySize:CGFloat = 14
    
    static let colorButton = UIColor(red:1.00, green:0.33, blue:0.00, alpha:1.0)
    static let red = UIColor(red:0.86, green:0.00, blue:0.00, alpha:1.0)
    static let likeRed = UIColor(red:0.92, green:0.21, blue:0.00, alpha:1.0)
    
}

class Messages {
    static let failedToLoadSearchResults: String = "Couldn't load search results"
    static let noInternet: String = "No Internet connection"
    
}

class GlobalConfig {
    
    // Speech Services
    static let speechRecognitionLanguage: String = "en-US"
    static let speechRecognitionKey: String = "AIzaSyBzpngaeyjazZdABhn8XsAq2faYgGuHORk"
    static let speechRecognitionHost : String = "speech.googleapis.com"
    static let speechRecognitionPhraseHintsResource: URL = URL(string: "https://storage.googleapis.com/data.cerebel.io/resources/faer/settings.json")!
    
    // Map Services
    static let mapAPIKey: String = "AIzaSyDSQApM8qZRfEqSECBJgJeLecP5V_Pjh04"
    
    // Feed Config
    static let faerFeedHost: String = "https://api.cerebel.io/v3/store/faer/feed"
    static let faerFeedAPIKey: String = "AonNLZaEXMtLiHdqJqqGQjKrVRGMhq"
    
    // Product Config
    static let faerProductHost: String = "https://api.cerebel.io/v3/store/faer/item/"
    static let faerProductAPIKey: String = "AonNLZaEXMtLiHdqJqqGQjKrVRGMhq"
    
    // Brand Config
    static let faerBrandHost: String = "https://api.cerebel.io/v3/store/faer/brand/"
    static let faerBrandAPIKey: String = "AonNLZaEXMtLiHdqJqqGQjKrVRGMhq"

    // Search Config
    static let faerSearchHost: String = "https://api.cerebel.io/v3/store/faer/search"
    static let faerSearchAPIKey: String = "AonNLZaEXMtLiHdqJqqGQjKrVRGMhq"
    
    // Search Teaser
    static let faerSearchTeaserHost: String = "https://api.cerebel.io/v3/store/faer/search/teasers"
    
    // User Config
    static let faerUserHost: String = "https://api.cerebel.io/v3/store/faer/user"
    static let faerUserAPIKey: String = "AonNLZaEXMtLiHdqJqqGQjKrVRGMhq"
    
    // Autocomplete Config
    static let faerAutoCompleteHost: String = "https://api.cerebel.io/store/faer/suggest"
    static let faerAutoCompleteAPIKey: String = "AonNLZaEXMtLiHdqJqqGQjKrVRGMhq"
    
    //Surveys Config
    static let surveyResource: URL = URL(string: "https://storage.googleapis.com/data.cerebel.io/resources/faer/survey.json")!
    
    // Supported locales
    static let supportedLocaleIdentifiers: [String] = ["de_DE", "en_US", "en_GB", "da_DK", "de_DE"]

}

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // init firebase analytics
        #if RELEASE
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        #endif
        
        FirebaseApp.configure()
        
        if User.shared.onboardingStatus == .completed {
            User.shared.usageFrequency += 1
            User.shared.save()
        }
        
        //init facebook analytics
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
       // User.shared.needsUpdate()
        
        // handle app invocation from notification
        if let userInfo = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            
            // this is called when a background push notification is tapped
            AppNotifications.shared.new(userInfo: userInfo, context: .launched)
            
        }
        
        self.configureNotifications(application: application)
        
        InstanceID.instanceID().instanceID(handler: { (result, error) in
            if let error = error {
                print("Error fetching remote instange ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
            }
            
            let instanceID: String = result?.instanceID ?? "empty"
            let fcmToken: String = Messaging.messaging().fcmToken ?? "empty"
            
            print("Analytics.appInstanceID() \(Analytics.appInstanceID()) InstanceID.instanceID() \(instanceID) fcmToken \(fcmToken)");
        })

        self.setupNavigationBarAppearance()

        return true
    }
    
    private func setupNavigationBarAppearance() {
        UINavigationBar.appearance().tintColor = .black
        
        let font:UIFont = UIFont(name: StyleGuide.font.headline.rawValue, size: 18.0)!
        let navbarTitleAtt = [
            NSAttributedString.Key.font:font
        ]
        UINavigationBar.appearance().titleTextAttributes = navbarTitleAtt
    }

    
    private func configureNotifications(application: UIApplication) {
        
        // ios
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus != .denied {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        // firebase
        
        Messaging.messaging().delegate = self


    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        User.shared.save()
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        User.shared.needsUpdate()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AppEventsLogger.activate(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
         User.shared.save()
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return SDKApplicationDelegate.shared.application(application, open: url, options: options)
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
}


extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

       // AppNotifications.shared.new(notification: notification.request, context: .running) // uncomment to directly handle event if app is in foreground
        // Change this to your preferred presentation option

      if AppNotifications.shared.shouldPresentNotification(notification: notification.request) {
            completionHandler([.alert, .sound, .badge])
        } else {
            completionHandler([])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // handle local notification
        // called when a notification is received and tapped when the app is running foreground or background
        AppNotifications.shared.new(notification: response.notification.request, context: .running)
        
        completionHandler()
    }
}

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
        AppNotifications.shared.register(deviceToken: fcmToken)
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("messaging:remoteMessage:Received remoteMessagedata message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}

