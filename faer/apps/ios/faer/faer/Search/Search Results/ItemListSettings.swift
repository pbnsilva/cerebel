//
//  ItemListSettings.swift
//  faer
//
//  Created by pluto on 15.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

protocol ItemListSettingsDelegate {
    func didUpdate()
}

struct ItemListSettings {
    
    var delegate: ItemListSettingsDelegate?
    
    var query: Any? {
        didSet {
            self.delegate?.didUpdate()
        }
    }
    
    var sorting: ItemListSettings.sortingType = .relevance
    
    var sessionID: String?
    
    // filters
    
    var locationEnabled: Bool = false // if set, the list has item related to a specific location
    
    var price: Range = ItemListSettings.allPriceRange // filter by price
    
  //  var brand: String? // by brand
    
    var brands: [String]?
    
    var category: [String]? // by one or more categories
    
    var color: [String]?
    
    var size: Int = ItemList.defaultPageSize

    var onSale: Bool = false
    
    // MARK: Settings
    
    static let allPriceRange: Range = 0..<5000 // show all products
    
    enum sortingType: String { // raw values must match the cell's reuse identifiers in storyboard
        case relevance
        case priceLowToHigh
        case priceHighToLow
    }
    
    init() {
        
    }
    
    init(query: Any) {
        self.query = query
    }
    
    //MARK: Implementation
        
    private func getFilters() -> [String: Any] {
    
        var filters: [String: Any] = [:]
        
        let priceFieldName: String = "price.\(User.shared.preferredLocale.currencyCode?.lowercased() ?? "")"
        
        filters["gender"] = User.shared.gender.rawValue
        filters[priceFieldName] = ["gt": self.price.lowerBound, "lt": self.price.upperBound]
        
        if self.locationEnabled {
            filters["store_locations"] = [
                "distance": "100km",
                "location": [
                    "lat": User.shared.lastLocation?.coordinate.latitude ?? 0,
                    "lon": User.shared.lastLocation?.coordinate.longitude ?? 0
                ]
            ]
        }
        
        if let _ = self.brands {
            filters["brand"] = self.brands!
        }
        
        if let _ = self.category {
            filters["annotations.category"] = self.category!
        }

        
        if let _ = self.color {
            filters["annotations.color"] = self.color!
        }
        
        if self.onSale {
            filters["onSale"] = true
        }

        return filters
    
    }
    
    func asRequest() throws -> URLRequest {
        return try asRequest(offset: 0, size: self.size)
    }
    
    func asRequest(offset: Int, size: Int) throws -> URLRequest {
        
        var jsonBody: [String: Any] = [:]
        
        var searchType: String
        
        //configure request type
        switch self.query {
        case is URL:
            searchType = "image"
            
            jsonBody = ["image": ["source":
                (self.query as! URL).absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)]]
            
        case is String:
            searchType = "text"
            
            jsonBody = ["query": self.query as! String]
            jsonBody["showGuided"] = true
            
        case is UIImage:
            searchType = "image"
            guard let imageData = (self.query as! UIImage).jpegData(compressionQuality: 0.5) else {
                throw SerializationError.invalid("Invalid query: Couldn't serialize image data to JPEG", "")
            }
            
            jsonBody = ["image": ["content": imageData.base64EncodedString(options: .lineLength64Characters)]]
            jsonBody["showGuided"] = false
            
        default:
            searchType = "text"
            break;
        }
        
        jsonBody["size"] = size
        jsonBody["offset"] = offset
        jsonBody["showSimilar"] = true
        
        // sorting
        let priceFieldName: String = "price.\(User.shared.preferredLocale.currencyCode?.lowercased() ?? "")"

        if self.sorting != .relevance {
            let order: String
            
            if self.sorting == .priceHighToLow {
                order = "desc"
            } else {
                order = "asc"
            }
            
            jsonBody["sortByField"] = [
                priceFieldName: [
                    "order": order
                ]
            ]
        }
        
        jsonBody["filters"] = self.getFilters()
        
        // session id
        if let _ = self.sessionID {
            jsonBody["sessionID"] = self.sessionID!
        }
        
        // fields
        
        jsonBody["fields"] = ["id", "name", "brand", "brand_id", "url", "gender", "description", "image_url", "tags", "price", "annotations", "stores", "original_price", "promotion", "share_url"]
        
        // serialize data
        
        let data: Data = try JSONSerialization.data(withJSONObject: jsonBody, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body

        // perform request
        var request = URLRequest(url: URL(string: "\(GlobalConfig.faerSearchHost)/\(searchType)")!)
        request.httpBody = data
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "X-Cerebel-Token": GlobalConfig.faerSearchAPIKey,
            "Accept": "application/json"
        ]
        return request
    }
    
}
