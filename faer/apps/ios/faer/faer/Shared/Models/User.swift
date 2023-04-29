//
//  User.swift
//  faer
//
//  Created by pluto on 28.09.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import os.log
import StoreKit
import CoreLocation
import UserNotifications
import FacebookCore

class User: NSObject, NSCoding {
    
    enum Onboarding: Int {
        case newUser = 0
        case permissionDenied = 1
        case completed = 2
    }
    
    enum Gender: String {
        case male = "men"
        case female = "women"
        case unknown = "unknown"
        case all = "all"
    }
    
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("faerUsers")
    
    static let shared = User()
    
    //MARK: Properties
    
    private let locationManager: CLLocationManager = CLLocationManager()
    
    private var isSaving: Bool = false
    
    private (set) var likes: Set<Item>
    
    var onboardingStatus : Onboarding
    
    var gender: Gender {
        didSet {
            NotificationCenter.default.post(name: .userGenderUpdated, object: nil, userInfo: nil)
        }
    }
    
    var preferredLocale: Locale
    
    var firstName: String?
    
    var name: String?
    
    var email: String?
    
    var notificationPermissions: NotificationPermissions?
    
    var usageFrequency: Int
    
    var lastLocation: CLLocation?
    
    //MARK: Types
    
    struct PropertyKey {
        static let likes = "likes"
        static let usageFrequency = "usageFrequency"
        static let gender = "gender"
        static let onboardingStatus = "onboardingStatus"
        static let currency = "currency"
        static let locale = "locale"
        static let firstName = "firstName"
        static let name = "name"
        static let email = "email"
        static let notificationPermissions = "notificationPermissions"
        static let lastLocation = "lastLocation"
    }
    
    //MARK: Main
    
    static private func fromArchive() -> User? {
        guard
            let data = try? Data(contentsOf: User.ArchiveURL),
            let user = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? User
        else { return nil }
        return user
    }
    
    override init() {
        // init from NSCoding if user already exists
        guard
            let user = User.fromArchive()
        else {
                self.likes = []
                self.usageFrequency = 1
                self.gender = .unknown
                self.onboardingStatus = .newUser
                self.preferredLocale = Locale(identifier: GlobalConfig.supportedLocaleIdentifiers.first!)
                self.notificationPermissions = NotificationPermissions()
                //
                super.init()
                self.updateLocation()
                self.save()
                return
        }
        
        self.likes = user.likes
        self.usageFrequency = user.usageFrequency
        self.gender = user.gender
        self.onboardingStatus = user.onboardingStatus
        self.preferredLocale = user.preferredLocale
        self.notificationPermissions = user.notificationPermissions
        //
        super.init()
        self.updateLocation()
    }
    
    init(likes: Set<Item>, usageFrequency: Int, gender: Gender, onboardingStatus: Onboarding, preferredLocale: Locale) {
        
        self.likes = likes
        self.usageFrequency = usageFrequency
        self.gender = gender
        self.preferredLocale = preferredLocale
        self.onboardingStatus = onboardingStatus
        
        super.init()
        
    }
    
    // reset to default, used for user testing
    func resetAllData() {
        
        self.onboardingStatus = .newUser
        self.gender = .unknown
        self.name = nil
        self.firstName = nil
        self.email = nil
        self.likes.removeAll()
    }
    
    private func askUserForAppRating() {
        DispatchQueue.main.async {
            SKStoreReviewController.requestReview()
        }
    }
    
    // handle likes - start
    
    private func likeActionIfNeeded(for item: Item) {
        
        // event logging
        Log.Tap.addToLikes(item: item)
        
        // register for push notifications
        AppNotifications.shared.askForPermission()
        AppNotifications.shared.register(item: item)
        
        // ask for app rating
        if self.likes.count == 4 {
            self.askUserForAppRating()
        }
        if self.likes.count == 12 {
            self.askUserForAppRating()
        }
    }
    
    func addLike(item: Item) {
        
        // save like
        let (inserted, _) = self.likes.insert(item)
        if inserted {
            self.save()
        }
        
        self.likeActionIfNeeded(for: item)
    }
    
    func removeLike(item: Item) {
        guard let _ = self.likes.remove(item) else {
            return
        }
        
        Log.Tap.removeFromLikes(item: item)
        
        AppNotifications.shared.unregister(item: item)
        
        self.save()
    }
    
    func isLiked(item: Item) -> Bool {
        return self.likes.contains(item)
    }
    
    func likeBy(id: String) -> Item? {
        return self.likes.first {$0.id == id}
    }
    
    // handle likes - end
    
    private func updateLocation() {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.locationManager.distanceFilter = 100.0  // In meters.
        self.locationManager.delegate = self
        
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse else { return }
        self.locationManager.startUpdatingLocation()
    }
    
    //MARK: NSCoding
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        let onboardingStatusRawValue = aDecoder.decodeInteger(forKey: PropertyKey.onboardingStatus)

        guard
            let genderRawValue = aDecoder.decodeObject(forKey: PropertyKey.gender) as? String,
            let gender = Gender(rawValue: genderRawValue),
            let likes: Set<Item> = aDecoder.decodeObject(forKey: PropertyKey.likes) as? Set<Item>,
            let onboardingStatus = Onboarding(rawValue: onboardingStatusRawValue)
        else {
                return nil
        }
        // don't require locale when upgrading from < 1.89 versions
        var locale = aDecoder.decodeObject(forKey: PropertyKey.locale) as? Locale ?? Locale(identifier: GlobalConfig.supportedLocaleIdentifiers.first!)

        let uf = aDecoder.decodeInteger(forKey: PropertyKey.usageFrequency)
        
        //decode locale
        // support for older price model
        if let currency = aDecoder.decodeObject(forKey: PropertyKey.currency) as? String {
            switch currency {
            case "€":
                locale = Locale(identifier: "de_DE") // using Germany as proxy for EUR
            case "$":
                locale = Locale(identifier: "en_US")
            case "£":
                locale = Locale(identifier: "en_GB")
            case ".kr":
                locale = Locale(identifier: "da_DK")
            default:
                locale = Locale(identifier: "de_DE")
            }
        }
        
        self.init(likes: likes, usageFrequency: uf, gender: gender, onboardingStatus: onboardingStatus, preferredLocale: locale)
        
        // decode user data
        self.lastLocation = aDecoder.decodeObject(forKey: PropertyKey.lastLocation) as? CLLocation
        self.name =  aDecoder.decodeObject(forKey: PropertyKey.name) as? String
        self.firstName =  aDecoder.decodeObject(forKey: PropertyKey.firstName) as? String
        self.email =  aDecoder.decodeObject(forKey: PropertyKey.email) as? String
        
        // backfill notifications for older versions
        
        self.notificationPermissions = aDecoder.decodeObject(forKey: PropertyKey.notificationPermissions) as? NotificationPermissions ?? NotificationPermissions()
        
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.likes, forKey: PropertyKey.likes)
        aCoder.encode(self.usageFrequency, forKey: PropertyKey.usageFrequency)
        aCoder.encode(self.gender.rawValue, forKey: PropertyKey.gender)
        aCoder.encode(self.onboardingStatus.rawValue, forKey: PropertyKey.onboardingStatus)
        aCoder.encode(self.preferredLocale, forKey: PropertyKey.locale)
        
        aCoder.encode(self.firstName, forKey: PropertyKey.firstName)
        aCoder.encode(self.name, forKey: PropertyKey.name)
        aCoder.encode(self.email, forKey: PropertyKey.email)
        aCoder.encode(self.notificationPermissions, forKey: PropertyKey.notificationPermissions)
        aCoder.encode(self.lastLocation, forKey: PropertyKey.lastLocation)
    }
    
    public func save() {
        self.isSaving = true
        do {
            let data: Data = NSKeyedArchiver.archivedData(withRootObject: self)
            try data.write(to: User.ArchiveURL)
            os_log("User successfully saved.", log: OSLog.default, type: .debug)
        } catch {
            os_log("Failed to save user...", log: OSLog.default, type: .error)
        }
        
        self.isSaving = false
    }
    
    // User Management / Authentication
    
    func needsAuthentication() -> Bool {
        /*
         if let _ = AccessToken.current {
         // User is logged in, use 'accessToken' here.
         return true
         }
         */
        return false
    }
    
    func needsUpdate() {
        /*// disable login features for now
         struct FBProfileRequest: GraphRequestProtocol {
         typealias Response = GraphResponse
         
         var graphPath: String = "/me"
         var parameters: [String: Any]? = ["fields": "id, name, email, first_name, picture"]
         var accessToken: AccessToken? = .current
         var httpMethod: GraphRequestHTTPMethod = .GET
         var apiVersion: GraphAPIVersion = 2.7
         }
         
         let request = FBProfileRequest()
         request.start { _, result in
         switch result {
         case .success(let response):
         if let dict = response.dictionaryValue {
         self.email = dict["email"] as? String
         self.name = dict["name"] as? String
         self.firstName = dict["first_name"] as? String
         }
         
         case .failed(let error):
         print("Graph Request Failed: \(error)")
         }
         }
         */
    }
}

extension Notification.Name {
    static let userLocationUpdated = Notification.Name("userLocationUpdated")
    static let userGenderUpdated = Notification.Name("userGenderUpdated")
}

// MARK: - CLLocationManagerDelegate
extension User: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Process the received location update
        if let _ = locations.last {
            self.lastLocation = locations.last
        }
        NotificationCenter.default.post(name: .userLocationUpdated, object: nil, userInfo: nil)
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        self.locationManager.startUpdatingLocation()
    }
}

