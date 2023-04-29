//
//  Store.swift
//  faer
//
//  Created by venus on 17.04.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

// helper struct as CLLocation doesn't conform to Decodable
fileprivate struct StoreService: Decodable {
    
    struct Location: Decodable {
        var lat: Double
        var lon: Double
    }
    
    var name: String
    var address: String
    var city: String
    var country: String
    var postal_code: String
    var location: Location

}

class Store: NSObject, NSCoding, Decodable {
    
    //MARK: Types
    struct PropertyKey {
        static let location = "location"
        static let name = "name"
        static let address = "address"
        static let city = "city"
        static let country = "country"
        static let postalCode = "postal_code"
        static let lat = "latitude"
        static let lon = "longitude"
    }
    
    var location: CLLocation
    
    var name: String
    var city: String
    var country: String
    var postalCode: String
    var address: String?

    override func isEqual(_ object: Any?) -> Bool {
        guard
            let other = object as? Store,
            self.location == other.location,
            self.name == other.name,
            self.city == other.city,
            self.postalCode == other.postalCode
            else { return false }
        return true
    }
    
    convenience init(latitude: Double, address: String?, longitude: Double, name: String, city: String, country: String, postalCode: String) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        self.init(location: location, name: name, address: address, city: city, country: country, postalCode: postalCode)
    }
    
    init(location: CLLocation, name: String, address: String?, city: String, country: String, postalCode: String) {
        self.location = location
        self.name = name
        self.country = country
        self.city = city
        self.postalCode = postalCode
        self.address = address
    }
    
    //MARK: Decodable
    
    required init(from decoder: Decoder) throws {
        let rawResponse = try StoreService(from: decoder)
        self.name = rawResponse.name
        self.city = rawResponse.city
        self.country = rawResponse.country
        self.postalCode = rawResponse.postal_code
        self.address = rawResponse.address
        self.location = CLLocation(latitude: rawResponse.location.lat, longitude: rawResponse.location.lon)
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        // required
        aCoder.encode(location, forKey: PropertyKey.location)
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(address, forKey: PropertyKey.address)
        aCoder.encode(city, forKey: PropertyKey.city)
        aCoder.encode(country, forKey: PropertyKey.country)
        aCoder.encode(postalCode, forKey: PropertyKey.postalCode)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        let location: CLLocation
        
        //maintain NSCoding compatiblity for Location object with version before 1.91
        
        if let oldClass = aDecoder.decodeObject(forKey: PropertyKey.location) as? Location {
            location = CLLocation(latitude: oldClass.lat, longitude: oldClass.lon)
        } else {
            guard let _ = aDecoder.decodeObject(forKey: PropertyKey.location) as? CLLocation else {
                return nil
            }
            location = aDecoder.decodeObject(forKey: PropertyKey.location) as! CLLocation
        }
    
        guard
            let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String,
            let address = aDecoder.decodeObject(forKey: PropertyKey.address) as? String,
            let city = aDecoder.decodeObject(forKey: PropertyKey.city) as? String,
            let postalCode = aDecoder.decodeObject(forKey: PropertyKey.postalCode) as? String,
            let country = aDecoder.decodeObject(forKey: PropertyKey.country) as? String else {
                return nil
        }
        
        self.init(location: location, name: name, address: address, city: city, country: country, postalCode: postalCode)
    }
    
}

// Init from JSON
extension Store {
    convenience init?(json: [String: Any]) {
        
        guard
            let locationData = json["location"] as? [String: Any],
            let location: CLLocation = CLLocation(json: locationData),
            let name = json["name"] as? String,
            let city = json["city"] as? String,
            let country = json["country"] as? String,
            let postalCode = json["postal_code"] as? String
            else {
                return nil
        }
        
        self.init(location: location, name: name, address: json["address"] as? String, city: city, country: country, postalCode: postalCode)
        
    }
}

extension CLLocation {
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard
            let other = object as? CLLocation,
            self.coordinate.latitude == other.coordinate.latitude,
            self.coordinate.longitude == other.coordinate.longitude
            else { return false }
        return true
    }
    
    convenience init?(json: [String: Any]) {
        
        guard
            let lat = json["lat"] as? Double,
            let lon = json["lon"] as? Double
        else {
                return nil
        }
        
        self.init(latitude: lat, longitude: lon)
        
    }
    
}
