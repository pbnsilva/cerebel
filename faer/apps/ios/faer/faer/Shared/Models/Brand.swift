//
//  Brand.swift
//  faer
//
//  Created by pluto on 30.01.19.
//  Copyright © 2019 pluto. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAnalytics

class Brand: NSObject, NSCoding {
    
    typealias Category = String
    
    //MARK: Types
    struct PropertyKey {
        static let id = "id"
        static let name = "name"
        static let tags = "tags"
        static let priceRange = "priceRange"
        static let categories = "categories"
        static let location = "location"
        static let story = "story"
        static let popularProducts = "popularProducts"
    }
    
    static var tagIcons: [String: String] = [
        "fair working conditions": "criteria-fairwages",
        "gots certified": "criteria-gots",
        "handmade": "criteria-handmade",
        "local production": "criteria-localProduction",
        "made locally": "criteria-localProduction",
        "peta approved": "criteria-PETAapproved",
        "recycled": "criteria-recycled",
        "upcycled": "criteria-recycled",
        "vegan": "criteria-vegan",
        "vintage": "criteria-vintage",
        "organic": "criteria-organicfabrics",
        "natural fabrics": "criteria-naturalfabrics",
        "natural": "criteria-naturalfabrics",
        "socially conscious": "criteria-socialcause",
        "community work": "criteria-socialcause",
        "women empowerment": "criteria-socialcause",
        "social cause": "criteria-socialcause",
        "fairtrade": "criteria-fairtrade",
        "fair wear foundation": "criteria-fairwear",
        "plastic free": "criteria-plasticfree",
        "factory locations": "criteria-factorylocations",
        "closed loop": "criteria-closedloop",
        "chemical free": "criteria-chemicalfree"
    ]
    
    var id: String
    var name: String
    var priceRange: String
    var tags: [String]?
    var location: String?
    var story: String?
    
    lazy var categories: [Category: [Item]] = [:]
    lazy var popularProducts: [Item] = []
    
    //MARK: Init
    
    init(story: String?, id: String, name: String, priceRange: String, location: String?) {
        self.id = id
        self.name = name
        self.priceRange = priceRange
        self.location = location
        self.story = story
    }
    
    //MARK: Equatable
    
    override var hash: Int {
        return "\(self.name)\(self.id)".hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        
        guard let brand = object as? Brand else {
            return false
        }
        
        guard self.id == brand.id else { return false }
        return true
        
    }
    
    static func ==(lhs: Brand, rhs: Brand) -> Bool {
        return lhs.id == rhs.id
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        // required
        aCoder.encode(self.id, forKey: PropertyKey.id)
        aCoder.encode(self.name, forKey: PropertyKey.name)
        aCoder.encode(self.tags, forKey: PropertyKey.tags)
        aCoder.encode(self.priceRange, forKey: PropertyKey.priceRange)
        aCoder.encode(self.categories, forKey: PropertyKey.categories)
        aCoder.encode(self.location, forKey: PropertyKey.location)
        aCoder.encode(self.story, forKey: PropertyKey.story)
        aCoder.encode(self.popularProducts, forKey: PropertyKey.popularProducts)
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard
            let id = aDecoder.decodeObject(forKey: PropertyKey.id) as? String,
            let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String,
            let priceRange = aDecoder.decodeObject(forKey: PropertyKey.priceRange) as? String
            else {
                return nil
        }
        
        self.init(
            story: aDecoder.decodeObject(forKey: PropertyKey.story) as? String,
            id: id,
            name: name,
            priceRange: priceRange,
            location: aDecoder.decodeObject(forKey: PropertyKey.location) as? String)
        
        self.tags = aDecoder.decodeObject(forKey: PropertyKey.tags) as? [String]
        self.categories = aDecoder.decodeObject(forKey: PropertyKey.categories) as? [Category: [Item]] ?? [:]
        self.popularProducts = aDecoder.decodeObject(forKey: PropertyKey.popularProducts) as? [Item] ?? []
        
    }
}


// Init from JSON
extension Brand {
    
    private static func categories(json: [[String: Any]]) -> [Category: [Item]]? {
        
        var result: [Category: [Item]] = [:]
        
        for category in json {
            
            guard
                let name: String = category["name"] as? String,
                let products: [[String: Any]] = category["products"] as? [[String: Any]] else {
                    continue
            }
            
            let items: [Item] = products.compactMap { return try? Item(json: $0)}
            
            result[name] = items
            
        }
        
        return result
        
    }
    
    convenience init(data: Data) throws {
        
        guard
            let dict = try? JSONSerialization.jsonObject(with: data, options: []),
            let brandData = dict as? [String: Any],
            let json = brandData["brand"] as? [String: Any]
            else {
                throw SerializationError.invalid("invalid brand data", data)
        }
        
        guard let id = json["id"] as? String else {
            throw SerializationError.missing("brand id")
        }
        
        guard let name = json["name"] as? String else {
            throw SerializationError.missing("brand name")
        }
        guard let priceRange: String = json["price_range"] as? String else {
            throw SerializationError.missing("price_range format or is missing")
        }
        
        self.init(
            story: json["description"] as? String,
            id: id,
            name: name,
            priceRange: priceRange,
            location: json["location"] as? String
        )
        
        self.tags = (json["tags"] as? [String])?.compactMap{ return $0.trimmingCharacters(in: .whitespaces) }
                
        //categories
        if
            let categoriesData: [[String: Any]] = json["categories"] as? [[String: Any]],
            let categories = Brand.categories(json: categoriesData)
        {
            self.categories = categories
        }
        
        // popular products
        if let pproducts: [[String: Any]] = json["popular_products"] as? [[String: Any]] {
            self.popularProducts = pproducts.compactMap { return try? Item(json: $0)}
        }
        
    }
    
    // returns the brandId for a given brand name
    static func id(for brandName: String, completion: @escaping (String?, Error?) -> Void) {
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        ItemList.using(query: brandName) { (settings, list, error) in
            guard
                error == nil,
                list != nil,
                let brandId = list?.items.first?.brandId
                else {
                    completion(nil, error)
                    return
            }
            
            completion(brandId, nil)
            
        }
        
    }
    
    static func load(brandId: String, completion: @escaping (Brand?, Error?) -> Void) {
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        let brandAPIUrl: String = "\(GlobalConfig.faerBrandHost)\(brandId)?token=\(GlobalConfig.faerFeedAPIKey)&gender=\(User.shared.gender.rawValue)" //TODO refactor into config
        let requestUrl = URL(string: brandAPIUrl)!
        var request = URLRequest(url: requestUrl)
        
        request.setValue(Analytics.appInstanceID(), forHTTPHeaderField: "X-User-Id") // used for personalizing feed
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard let data = data, error == nil, let resp = response as? HTTPURLResponse, resp.statusCode == 200 else {
                completion(nil, error)
                return
            }
            
            do {
                
                let result: Brand = try Brand(data: data)
                
                completion(result, nil)
                
            } catch {
                completion(nil, error)
                return
            }
            
            }.resume()
        
    }
    
}



// MARK: - Location-based features
