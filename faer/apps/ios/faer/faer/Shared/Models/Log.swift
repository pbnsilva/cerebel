//
//  Analytics.swift
//  faer
//
//  Created by pluto on 06.11.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import UIKit

import FacebookCore
import FBSDKCoreKit
import FirebaseAnalytics
import AdSupport

class Log {
    
    enum ParentView: String {
        case Feed = "Feed"
        case SearchResult = "SearchResult"
        case ProductDetail = "ProductDetail"
        case ProductDetailRecommendations = "ProductDetailRecommendations"
        case Shop = "Shop"
        case BrandSpotlight = "BrandSpotlight"
        case Likes = "Likes"
    }
    
    public static var identifier: String {
        get {
            guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
                return "ad_tracking_disabled"
            }
            
            return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        }
    }
    
    static func serialize(_ item: Item) -> [String: Any] {
        
        guard let price = item.preferredPrice() else { return [:] }
        
        var parameters: [String: Any] = [:]
        
        parameters = [AnalyticsParameterItemID: item.id as NSString,
                      AnalyticsParameterItemName: item.name as NSString,
                      AnalyticsParameterItemBrand: item.brand as NSString,
                      AnalyticsParameterPrice: price.value as NSNumber,
                      AnalyticsParameterCurrency: price.currencyCode as NSString
        ]
        
        return parameters
    }
    
    class Event {
        
        public static func onboardingBegin() {
            Analytics.logEvent(AnalyticsEventTutorialBegin, parameters: nil)
        }
        
        public static func onboardingEnd() {
            Analytics.logEvent(AnalyticsEventTutorialComplete, parameters: nil)
            
            //Facebook
            let params : AppEvent.ParametersDictionary = [
                .successful : NSNumber(value: 1)
            ]
           AppEventsLogger.log(AppEvent(name: .completedTutorial, parameters: params))
            
        }
        
        public static func newsletterSubscribed(email: String) {
            Analytics.logEvent("newsletter_subscribed", parameters: [
                "timestamp": NSDate().timeIntervalSince1970 as NSObject,
                "device_id": Log.identifier as NSObject,
                "email": email as NSObject
                ])
        }
        
        public static func register(deviceToken: String) {
            Analytics.logEvent("fcm_register_token", parameters: [
                "deviceToken": deviceToken as NSString
                ])
        }
        
        public static func feedback(email: String, text: String) {
            Analytics.logEvent("inapp_setting_feedback", parameters: [
                "email": text as NSObject,
                "text": text as NSObject
                ])
        }
        
    }
    
    // MARK: In-App NPS Survey
    
    class Survey {
        
        public static func began() {
            Analytics.logEvent("inapp_survey_began", parameters: [
                "timestamp": NSDate().timeIntervalSince1970 as NSObject,
                "device_id": Log.identifier as NSObject
                ])
        }

        public static func cancelled() {
            Analytics.logEvent("inapp_survey_cancelled", parameters: [
                "timestamp": NSDate().timeIntervalSince1970 as NSObject,
                "device_id": Log.identifier as NSObject
                ])
        }
        
        public static func completed() {
            Analytics.logEvent("inapp_survey_completed", parameters: [
                "timestamp": NSDate().timeIntervalSince1970 as NSObject,
                "device_id": Log.identifier as NSObject
                ])
        }


        public static func npsRating(score: Int) {
            Analytics.logEvent("inapp_survey_nps_score", parameters: [
                "timestamp": NSDate().timeIntervalSince1970 as NSObject,
                "device_id": Log.identifier as NSObject,
                "score": NSNumber(integerLiteral: score)
                ])
        }
        
        public static func comment(text: String) {
            Analytics.logEvent("inapp_survey_feedback_text", parameters: [
                "timestamp": NSDate().timeIntervalSince1970 as NSObject,
                "device_id": Log.identifier as NSObject,
                "feedback_text": text as NSObject
                ])
        }
        
        public static func email(email: String) {
            Analytics.logEvent("inapp_survey_email", parameters: [
                "timestamp": NSDate().timeIntervalSince1970 as NSObject,
                "device_id": Log.identifier as NSObject,
                "email": email as NSObject
                ])
        }

        
    }
    
    
    class Tap {
        
        public static func share(view: ParentView, parameters: [String: Any]) {
            Analytics.logEvent(AnalyticsEventShare, parameters: parameters)
        }
        
        public static func share(view: ParentView, item: Item) {
            let parameters: [String: Any] = Log.serialize(item)
            
            Analytics.logEvent(AnalyticsEventShare, parameters: parameters)
        }
        
        public static func map(view: ParentView, item: Item) {
            let parameters: [String: Any] = [
                AnalyticsParameterContentType: "\(view.rawValue);view map;\(item.brand)"
            ]
            
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: parameters)
        }
        
        public static func addToLikes(item: Item) {
            
            guard let price = item.preferredPrice() else { return }
            
            let parameters: [String: Any] = Log.serialize(item)
            
            Analytics.logEvent(AnalyticsEventAddToWishlist, parameters: parameters)
            
            //Facebook
            let params : AppEvent.ParametersDictionary = [
                .contentId : item.id,
                .contentType : item.annotations?.category?.first ?? "product",
                .currency : price.currencyCode
            ]
            let event = AppEvent(name: .addedToWishlist, parameters: params, valueToSum: price.value)
            AppEventsLogger.log(event)
        
        }
        
        public static func removeFromLikes(item: Item) {
            
            let parameters: [String: Any] = Log.serialize(item)
            
            Analytics.logEvent("remove_from_wishlist", parameters: parameters)
            
        }
        
        public static func item(view: ParentView, item: Item) {
            
            guard let price = item.preferredPrice() else { return }

            var parameters: [String: Any] = Log.serialize(item)
            parameters["AnalyticsParameterContentType"] = view.rawValue as NSString
            
            //Firebase
            Analytics.logEvent(AnalyticsEventSelectContent, parameters: parameters)
                        
            //Facebook
            let params : AppEvent.ParametersDictionary = [
                .contentType : item.annotations?.category?.first ?? "product",
                .contentId : item.id,
                .currency : price.currencyCode
            ]
            let event = AppEvent(name: .viewedContent, parameters: params, valueToSum: price.value)
            AppEventsLogger.log(event)
            
        }
        
        public static func search(_ query: Any) {
            let q: String
            
            switch query {
            case is String:
                q = query as! String
            case is UIImage:
                q = "<ImageSearch>"
            default:
                q = "<Unknown>"
            }
            // firebase
            let parameters: [String: Any] = [AnalyticsParameterSearchTerm: q as NSString]
            
            Analytics.logEvent(AnalyticsEventSearch, parameters: parameters)
            //facebook
            let params : AppEvent.ParametersDictionary = [
                .searchedString : q
            ]
            let event = AppEvent(name: .searched, parameters: params)
            AppEventsLogger.log(event)
            
        }
        
    }
    
    class View {
        
        public static func checkoutBegin(_ item: Item) {
            guard let price = item.preferredPrice() else { return }
            
            // Firebase
            let parameters: [String: Any] = Log.serialize(item)
            
            Analytics.logEvent(AnalyticsEventBeginCheckout, parameters: parameters)
            
            //Facebook
            let fbParameters : AppEvent.ParametersDictionary = [
                .contentId : item.preferredPrice()?.value ?? 0,
                .itemCount : NSNumber(value: 1),
                .currency : price.currencyCode
            ]
            
            let event: AppEvent = AppEvent(name: .initiatedCheckout, parameters: fbParameters, valueToSum: price.value)            
            AppEventsLogger.log(event)
            
        }
        
        
        public static func productDetail(_ item: Item) {
            guard let price = item.preferredPrice() else { return }

            // Firebase
            let parameters: [String: Any] = Log.serialize(item)
            
            Analytics.logEvent(AnalyticsEventViewItem, parameters: parameters)
            
            //Facebook
            let params : AppEvent.ParametersDictionary = [
                .contentType : item.annotations?.category?.first ?? "product",
                .contentId : item.id,
                .currency : price.currencyCode
            ]
            let event = AppEvent(name: .viewedContent, parameters: params, valueToSum: price.value)
            AppEventsLogger.log(event)
            
        }
        
        public static func searchResult(_ query: Any, totalItems: Int) {
            let q: String
            switch query {
            case is String:
                q = query as! String
            case is UIImage:
                q = "<ImageSearch>"
            default:
                q = "<Unknown>"
            }
            //Firebase
            
            let parameters: [String: Any] = [
                AnalyticsParameterSearchTerm: q as NSString,
                "result_count": totalItems as NSNumber
            ]
            
            Analytics.logEvent(AnalyticsEventViewSearchResults, parameters: parameters)
            
        }
        
        public static func shop(item: Item) {
            guard let price = item.preferredPrice() else { return }

            //Firebase
            let parameters: [String: Any] = Log.serialize(item)
            Analytics.logEvent(AnalyticsEventPresentOffer, parameters: parameters)
            //Facebook
            let params : AppEvent.ParametersDictionary = [
                .contentType : item.annotations?.category?.first ?? "product",
                .contentId : item.id,
                .currency : price.currencyCode
            ]
            let event = AppEvent(name: .custom("itemWebView"), parameters: params, valueToSum: price.value)
            AppEventsLogger.log(event)
            
        }
        
        
    }
    
}
