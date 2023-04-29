//
//  Notifications.swift
//  faer
//
//  Created by venus on 08.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import UserNotifications
import FirebaseMessaging
import Firebase
import FirebaseAnalytics

class AppNotifications {
    
    static let shared = AppNotifications()
    
    enum Context {
        case running
        case launched
    }
    
    typealias Topic = String
    
    class UserInfo {
        var payload: Any
        var segue: CommonSegues
        
        init?(_ userInfo: [AnyHashable : Any]?) {
            guard
                let segue = userInfo?["segue"] as? CommonSegues,
                let payload = userInfo?["payload"] else {
                return nil
            }
            
            self.payload = payload
            self.segue = segue
        }
    }
    
    struct Topics {
        
        static let productOnSale: String = "product_sale"
        static let brandProductsOnSale: String = "brand_sale"
    }
    
    func askForPermission() {
        
        // ask for permission to notify about events for liked items
        DispatchQueue.main.async {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {granted, _ in
            })
        }
    }
    
    func askForPermission(completion: @escaping (UNAuthorizationStatus) -> ()) {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {granted, _ in
                if granted {
                    return completion(UNAuthorizationStatus.authorized)
                } else {
                    return completion(UNAuthorizationStatus.denied)
                }
        })
    }
    
    func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> ()) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            completion(settings.authorizationStatus)
        }
    }
    
    func register(deviceToken: String) {
        
        // prepare data
        struct Payload: Codable {
            let fcmToken: String
            let os: String
            
            enum CodingKeys: String, CodingKey {
                case fcmToken = "fcm_token"
                case os
            }

        }
        
        // prepare request
        let url = URL(string: "\(GlobalConfig.faerUserHost)/\(Analytics.appInstanceID())")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(GlobalConfig.faerUserAPIKey, forHTTPHeaderField: "X-Cerebel-Token")
        let payload: Payload = Payload(fcmToken: deviceToken, os: "ios")
        guard let uploadData = try? JSONEncoder().encode(payload) else {
            return
        }
        
        // upload data
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    print ("server error")
                    return
            }
        }
        //print("notifications registered: ", deviceToken, " appInstace:",Analytics.appInstanceID(), " url:", url.absoluteString, " payload:", String(data: uploadData, encoding: .utf8)!)
        task.resume()

    }
    
    // registers notification for the item and topics
    func register(item: Item) {
        // wishlistProductOnSale
        if User.shared.notificationPermissions?.wishlistProductOnSale == true {
            Messaging.messaging().subscribe(toTopic: Topics.productOnSale) { error in
                print("Subscribed to sales notifications for \(item.id)")
            }
        }
    }
    
    // unregisters notification for the item and topics
    func unregister(item: Item) {
        // wishlistProductOnSale
        Messaging.messaging().unsubscribe(fromTopic: Topics.productOnSale)
    }
    
    func new(userInfo: [String : AnyObject], context: Context) {
        
        let content = UNMutableNotificationContent()
        content.userInfo = userInfo
        
        self.new(notification: UNNotificationRequest(identifier: "newRequest", content: content, trigger: nil), context: context)
        
    }
    
    func shouldPresentNotification(notification: UNNotificationRequest) -> Bool {
        
        let (payload, topic) = self.unserizalizePayload(notification: notification)
        
        if payload == nil {
            return false
        }
        
        if topic == Topics.productOnSale && User.shared.notificationPermissions?.wishlistProductOnSale != true {
            return false
        }
        
        if topic == Topics.brandProductsOnSale && User.shared.notificationPermissions?.brandProductsOnSale != true {
            return false
        }
        
        return true
    }
    
    private func unserizalizePayload(notification: UNNotificationRequest) -> (Any?, Topic?) {
        
        guard let topic: Topic = notification.content.userInfo["topic"] as? String else {
            return (nil, nil)
        }
        
        switch topic {
        case Topics.productOnSale:
            if let itemID = notification.content.userInfo["product_id"] as? String {
                return (User.shared.likeBy(id: itemID), topic)
            }
        case Topics.brandProductsOnSale:
            if let brandName = notification.content.userInfo["brand_name"] as? String {
                return (brandName, topic)
            }
        default:
            break;
        }
        
        return (nil, nil)
    }
    
    func new(notification: UNNotificationRequest, context: Context) {
        
        guard
            self.shouldPresentNotification(notification: notification),
            let (payload, topic) = self.unserizalizePayload(notification: notification) as? (Any, Topic)
        else { return }
        switch topic {
        case Topics.productOnSale:
            switch context {
            case .launched:
                (UIApplication.shared.windows.first?.rootViewController as? MainPageViewController)?.presentProduct(sender: payload)
            case .running:
                NotificationCenter.default.post(name: .presentProduct, object: nil, userInfo:
                    ["payload": payload,
                     "segue": CommonSegues.PDP
                    ])
            }
        case Topics.brandProductsOnSale:
            
            var search: ItemListSettings = ItemListSettings(query: payload)
            search.onSale = true
            
            switch context {
            case .launched:
                (UIApplication.shared.windows.first?.rootViewController as? MainPageViewController)?.presentSearchResult(sender: search)
            case .running:
                NotificationCenter.default.post(name: .presentSearchResult, object: nil, userInfo: ["payload": search,
                                                                                                    "segue": CommonSegues.searchResult
                    ])
            }
        default:
            break;
        }
    }
        
}

extension Notification.Name {
    // Push Notifications
    static let presentLikesView = Notification.Name("presentLikesView")
    static let presentProduct = Notification.Name("presentPDP")
    static let presentSearchResult = Notification.Name("presentSearchResult")
}
