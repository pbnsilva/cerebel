//
//  Location.swift
//  faer
//
//  Created by pluto on 17.11.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import CoreLocation

// This class is deprecated since 1.91; retained for backward compatibility in NSCOding

class Location: NSObject, NSCoding {
    
    //MARK: Types
    struct PropertyKey {
        static let lat = "lat"
        static let lon = "lon"
    }
    
    var lat: Double
    var lon: Double
    
    var cLLocationCoordinate2D: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.lat, longitude: self.lon)
        }
    }
    
    init(latitude: Double, longitude: Double) {
        self.lon = longitude
        self.lat = latitude
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        // required
        aCoder.encode(lat, forKey: PropertyKey.lat)
        aCoder.encode(lon, forKey: PropertyKey.lon)
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let lat = aDecoder.decodeObject(forKey: PropertyKey.lat) as? Double,
            let lon = aDecoder.decodeObject(forKey: PropertyKey.lon) as? Double else {
                return nil
        }
        self.init(latitude: lat, longitude: lon)
    }
    
    //MARK: JSON Decoder
    convenience init?(json: Any) {
        
        guard
            let j = json as? [String: Any],
            let l = j["location"] as? [String: Double],
            l[PropertyKey.lon] != nil,
            l[PropertyKey.lat] != nil
            else { return nil }
        
        self.init(latitude: l[PropertyKey.lat]!, longitude: l[PropertyKey.lon]!)
        
    }
    
}
