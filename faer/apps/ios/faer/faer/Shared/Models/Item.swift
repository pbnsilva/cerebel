//
//  Item.swift
//  faer
//
//  Created by pluto on 24.08.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

// MARK: - Item

class Item: NSObject, NSCoding {
    
    enum State: Int {
        case active = 0
        case updating = 1
        case inactive = 2
    }
    
    //MARK: Types
    struct PropertyKey {
        static let annotations = "annotations"
        static let brand = "brand"
        static let brandId = "brandId"
        static let name = "name"
        static let url = "url"
        static let id = "id"
        static let price = "price"
        static let originalPrice = "price"
        static let currency = "currency"
        static let bounds = "bounds"
        static let imageURLs = "imageURLs"
        static let likedAt = "likedAt"
        static let categories = "categories"
        static let about = "about"
        static let stores = "stores"
        static let prices = "prices"
        static let state = "state"
        static let promotion = "promotion"
        static let shareUrl = "shareUrl"
    }
    
    var brand: String
    var brandId: String
    var name: String
    var url: URL
    var id: String
    var shareUrl: URL
    
    var prices: Prices
    
    var bounds: CGRect?
    var imageURLs: [URL]
    var about: String?
    var promotion: String?
    var style: Style?
    var annotations: Annotations?
    var stores: [Store]?
    var state: State
    
    private (set) var likedAt: Date?
    var isLiked: Bool {
        get {
            if let _ = likedAt {
                return true
            } else {
                return false
            }
        }
        set {
            switch newValue {
            case true:
                self.likedAt = Date()
                User.shared.addLike(item: self)
            case false:
                User.shared.removeLike(item: self)
                self.likedAt = nil
            }
        }
    }
    
    init(brandId: String, brand: String, name: String, url: URL, id: String, prices: Prices, state: State, shareUrl: URL) {
        self.brandId = brandId
        self.brand = brand
        self.name = name
        self.url = url
        self.id = id
        self.prices = prices
        self.imageURLs = []
        self.state = .active
        self.shareUrl = shareUrl
    }
    
    private func pricesHash() -> Double {
        return self.prices.reduce(0, { $0 + $1.value + ($1.originalValue ?? 0.0)})
    }
    
    // return the price for the currently preferred locale
    func preferredPrice() -> Price? {
        for p in self.prices {
            if p.localeIdentifier == User.shared.preferredLocale.identifier {
                return p
            }
        }
        return nil
    }
    
    //MARK: Equatable
    
    override var hash: Int {
        let s: String = "\(brand)\(id)\(self.pricesHash())\(url.absoluteString)"
        return s.hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        
        guard let item = object as? Item else {
            return false
        }
        
        guard self.url == item.url else { return false }
        return true
        
    }
    
    static func ==(lhs: Item, rhs: Item) -> Bool {
        
        guard lhs.brand == rhs.brand,
            lhs.name == rhs.name,
            lhs.id == rhs.id,
            lhs.pricesHash() == rhs.pricesHash(),
            lhs.url == rhs.url else { return false }
        return true
    }
    
    //MARK: Custom functions
    public func isAvailable(completion: @escaping (Bool) -> Void) {
        URLSession.shared.dataTask(with: self.url) { (data, response, error) in
            guard let resp = response as? HTTPURLResponse, resp.statusCode == 404 else {
                completion(false)
                return
            }
            completion(true)
            }.resume()
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        // required
        aCoder.encode(self.name, forKey: PropertyKey.name)
        aCoder.encode(self.brand, forKey: PropertyKey.brand)
        aCoder.encode(self.brandId, forKey: PropertyKey.brandId)
        aCoder.encode(self.url, forKey: PropertyKey.url)
        aCoder.encode(self.id, forKey: PropertyKey.id)
        aCoder.encode(self.about, forKey: PropertyKey.about)
        aCoder.encode(self.prices, forKey: PropertyKey.prices)
        aCoder.encode(self.shareUrl, forKey: PropertyKey.shareUrl)
        
        // optionals
        aCoder.encode(self.annotations, forKey: PropertyKey.annotations)
        aCoder.encode(self.promotion, forKey: PropertyKey.promotion)
        aCoder.encode(self.bounds, forKey: PropertyKey.bounds)
        aCoder.encode(self.imageURLs, forKey: PropertyKey.imageURLs)
        aCoder.encode(self.likedAt, forKey: PropertyKey.likedAt)
        aCoder.encode(self.stores, forKey: PropertyKey.stores)
        aCoder.encode(self.state.rawValue, forKey: PropertyKey.state)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        var prices: Prices = []
        if let _ = aDecoder.decodeObject(forKey: PropertyKey.prices) as? Prices {
            prices = aDecoder.decodeObject(forKey: PropertyKey.prices) as! Prices
        } else {
            // migrate price model before version 1.86
            let priceValue: Double = aDecoder.decodeDouble(forKey: PropertyKey.price)
            guard
                let currencyCode = aDecoder.decodeObject(forKey: PropertyKey.currency) as? String,
                let locale = Price.locale(for: currencyCode)
                else { return nil }
            let price = Price(value: priceValue, localeIdentifier: locale.identifier)
            prices.append(price)
            // backfill missing prices
            for supportedLocale in GlobalConfig.supportedLocaleIdentifiers {
                if supportedLocale != locale.identifier {
                    prices.append(Price(value: Price.missingValue, localeIdentifier: supportedLocale))
                }
            }
        }
        
        guard
            let brand = aDecoder.decodeObject(forKey: PropertyKey.brand) as? String,
            let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String,
            let url = aDecoder.decodeObject(forKey: PropertyKey.url) as? URL,
            let id = aDecoder.decodeObject(forKey: PropertyKey.id) as? String else {
                return nil
        }
        
        // Must call designated initializer.
        let state: Item.State = State(rawValue: (aDecoder.decodeObject(forKey: PropertyKey.state) as? Int) ?? Item.State.active.rawValue)! // init as valid by default
        
        // support migration
        let shareUrl: URL
        if let su = aDecoder.decodeObject(forKey: PropertyKey.url) as? URL {
            shareUrl = su
        } else {
            shareUrl = url
        }
        
        // make brandId optional for older releases
        let brandId: String = aDecoder.decodeObject(forKey: PropertyKey.brandId) as? String ?? ""
        
        self.init(brandId: brandId, brand: brand, name: name, url: url, id: id, prices: prices, state: state, shareUrl: shareUrl)
        
        self.annotations = aDecoder.decodeObject(forKey: PropertyKey.annotations) as? Annotations
        
        self.about = aDecoder.decodeObject(forKey: PropertyKey.about) as? String
        
        self.promotion = aDecoder.decodeObject(forKey: PropertyKey.promotion) as? String
        
        self.bounds = aDecoder.decodeObject(forKey: PropertyKey.bounds) as? CGRect
        
        self.imageURLs = aDecoder.decodeObject(forKey: PropertyKey.imageURLs) as! [URL]
        
        self.stores = aDecoder.decodeObject(forKey: PropertyKey.stores) as? [Store]
        
        self.likedAt = aDecoder.decodeObject(forKey: PropertyKey.likedAt) as? Date
        
    }
}


// Init from JSON
extension Item {
    
    convenience init(json: [String: Any]) throws {
        
        guard let id = json["id"] as? String else {
            throw SerializationError.missing("item id")
        }
        guard let brand = json["brand"] as? String else {
            throw SerializationError.missing("item brand")
        }
        guard let brandId = json["brand_id"] as? String else {
            throw SerializationError.missing("item brandId for brand: \(brand) with product id: \(id)")
        }
        guard let name = json["name"] as? String else {
            throw SerializationError.missing("item name")
        }
        guard let rawURL: String = json["url"] as? String else {
            throw SerializationError.missing("Item URL has wrong format or is missing")
        }
        let url: URL
        if let _ = URL(string: rawURL) {
            url = URL(string: rawURL)!
        } else {
            if let u = rawURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) { // URL() fails on URLs with special characters like ß
                url = URL(string: u)!
            } else {
                throw SerializationError.missing("Item URL not serializable")
            }
        }
        
        guard let price: [String: Double] = json["price"] as? [String: Double] else {
            throw SerializationError.missing("Price has wrong format or is missing")
        }
        
        let originalPrice: [String: Double]? = json["original_price"] as? [String: Double]
        
        /* Unserialize prices */
        var prices: [Price] = []
        for localeIdentifier in GlobalConfig.supportedLocaleIdentifiers {
            let locale = Locale(identifier: localeIdentifier)
            guard
                let code = locale.currencyCode?.lowercased(),
                let _ = price[code]
                else { continue }
            // price
            prices.append(Price(value: price[code]!, originalValue: originalPrice?[code], localeIdentifier: localeIdentifier))
        }
        
        guard !prices.isEmpty else { throw SerializationError.missing("unable to unserialize price") }
        
        let shareUrl: URL
        if
            let rawURL: String = json["share_url"] as? String,
            let su = URL(string: rawURL) {
            shareUrl = su
        } else {
            shareUrl = url
        }
        
        self.init(brandId: brandId, brand: brand, name: name, url: url, id: id, prices: prices, state: .active, shareUrl: shareUrl)
        /* Unserialize optional meta data */
        
        self.about = json["description"] as? String
        
        self.promotion = json["promotion"] as? String
        
        if let imageUrls = json["image_url"] as? [String] {
            self.imageURLs = imageUrls.compactMap { return URL(string: $0)}
        } else {
            throw SerializationError.missing("image_url missing for itemID \(self.id)")
        }
        
        // unserialize optional original price aka price before discounted
        
        // unserialize annontations
        self.annotations = Annotations(itemJson: json)
        
        /* Unserialize Stores */
        stores = (json["stores"] as? [[String: Any]])?.compactMap{
                return Store(json: $0)
        }
        
    }
    
    /**
     Updates the item using the provided data.
     
     - Parameter data: JSON data with the new item information.
     
     - Throws: `SerializationError.invalid`
     If the provided JSON data is not valid item data.
     
     */
    
    // this is a copy of convenience init(json: [String: Any]); TODO refactor into proper model
    func update(data: Data) throws {
        
        let dict = try? JSONSerialization.jsonObject(with: data, options: [])
        
        guard
            let d = dict as? [String: Any],
            let matches = d["matches"] as? [String: Any],
            let items = matches["items"] as? [Any],
            let json = items.first as? [String: Any]
            else {
                throw SerializationError.invalid("invalid item data", data)
        }
        
        guard let id = json["id"] as? String else {
            throw SerializationError.missing("item id")
        }
        guard let brandId = json["brandId"] as? String else {
            throw SerializationError.missing("item brandId")
        }
        guard let brand = json["brand"] as? String else {
            throw SerializationError.missing("item brand")
        }
        guard let name = json["name"] as? String else {
            throw SerializationError.missing("item name")
        }
        guard let rawURL: String = json["url"] as? String else {
            throw SerializationError.missing("Item URL has wrong format or is missing")
        }
        let url: URL
        if let _ = URL(string: rawURL) {
            url = URL(string: rawURL)!
        } else {
            if let u = rawURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) { // URL() fails on URLs with special characters like ß
                url = URL(string: u)!
            } else {
                throw SerializationError.missing("Item URL not serializable")
            }
        }
        
        guard let price: [String: Double] = json["price"] as? [String: Double] else {
            throw SerializationError.missing("Price has wrong format or is missing")
        }
        
        /* Unserialize prices */
        let originalPrice: [String: Double]? = json["original_price"] as? [String: Double]
        var prices: [Price] = []
        for localeIdentifier in GlobalConfig.supportedLocaleIdentifiers {
            let locale = Locale(identifier: localeIdentifier)
            guard
                let code = locale.currencyCode?.lowercased(),
                let _ = price[code]
                else { continue }
            // price
           // prices.append(Price(value: price[code]!, originalValue: price[code]! - 10, localeIdentifier: localeIdentifier)) // uncomment for testing

            prices.append(Price(value: price[code]!, originalValue: originalPrice?[code], localeIdentifier: localeIdentifier))
        }
        
        guard !prices.isEmpty else { throw SerializationError.missing("unable to unserialize price") }
        
        if
            let rawURL: String = json["share_url"] as? String,
            let su = URL(string: rawURL) {
            self.shareUrl = su
        } else {
            self.shareUrl = url
        }
        
        self.brand = brand
        self.brandId = brandId
        self.name = name
        self.url = url
        self.id = id
        self.prices = prices
        
        guard let imageURLs = json["image_url"] as? [String] else { throw SerializationError.missing("image_url missing for itemID \(self.id)") }
        
        self.imageURLs.removeAll()
        
        for urlString in imageURLs {
            guard let url = URL(string: urlString) else { throw SerializationError.invalid("Invalid URL for image with itemID", self.id)}
            self.imageURLs.append(url)
        }
        
        /* Unserialize optional meta data */
        
        self.about = json["description"] as? String
        
        // unserialize annontations
        if let anons = Annotations(itemJson: json) {
            self.annotations = anons
        }
        
        /* Unserialize Stores */
        self.stores = (json["stores"] as? [[String: Any]])?.compactMap{
            return Store(json: $0)
        }
        
        if User.shared.isLiked(item: self) {
            User.shared.save() // update stored item information
        }

    }
    
    /**
     Updates the item by fetching the data from the remote source.
     
     - Returns: True if the data was retrieved and the item was updated. It will be true whether the data changed or not. If false, the update failed with more details provided in Error.
     */
    
    func update(completion: @escaping (Bool, Error?) -> Void) {
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        guard let url: URL = URL(string: "\(GlobalConfig.faerProductHost)\(self.id)?token=\(GlobalConfig.faerProductAPIKey)") else {
            fatalError()
        }
        
        let request: URLRequest = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard
                let _ = data,
                error == nil,
                let resp = response as? HTTPURLResponse
            else {
                completion(false, error)
                return
            }
            
            if resp.statusCode == 404 {
                self.state = .inactive
                completion(true, nil)
                return
            }
            
            do {
                
                try self.update(data: data!)
                
                completion(true, nil)
                
            } catch {
                completion(false, error)
                return
            }
            
            }.resume()
    }
}

// MARK: - Location-based features

extension Item {
    
    func storesInProximity() -> [Store] {
        guard let location = User.shared.lastLocation, let stores = self.stores else { return [] }
        
        // are any stores within 100km?
        let distance: CLLocationDistance = 100000 // in meters
        
        return stores.filter { return ($0.location.distance(from: location) < distance)}
        
    }
    
}

