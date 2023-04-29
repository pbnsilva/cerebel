//
//  Annotations.swift
//  faer
//
//  Created by pluto on 28.12.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation

class Annotations: NSObject, NSCoding {
    
    //MARK: Types
    struct PropertyKey {
        static let category = "category"
        static let color = "color"
        static let gender = "gender"
        static let style = "style"
        static let shape = "shape"
    }
    
    var category: [String]?
    var color: [String]?
    var gender: [String]?
    var style: [String]?
    var texture: [String]?
    var shape: [String]?
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        // optionals
        aCoder.encode(category, forKey: PropertyKey.category)
        aCoder.encode(color, forKey: PropertyKey.color)
        aCoder.encode(gender, forKey: PropertyKey.gender)
        aCoder.encode(style, forKey: PropertyKey.style)
        aCoder.encode(shape, forKey: PropertyKey.shape)
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        self.init()
        
        self.category = aDecoder.decodeObject(forKey: PropertyKey.category) as? [String]
        self.color = aDecoder.decodeObject(forKey: PropertyKey.color) as? [String]
        self.gender = aDecoder.decodeObject(forKey: PropertyKey.gender) as? [String]
        self.style = aDecoder.decodeObject(forKey: PropertyKey.style) as? [String]
        self.shape = aDecoder.decodeObject(forKey: PropertyKey.shape) as? [String]
        
    }
    
}

// Init from JSON
extension Annotations {
    convenience init?(itemJson: [String: Any]) {
        
        guard let json = itemJson["annotations"] as? [String: Any] else {
            return nil
        }
        
        self.init()
        
        self.category = json["category"] as? [String]
        self.color = json["color"] as? [String]
        self.gender = json["gender"] as? [String]
        self.style = json["style"] as? [String]
        self.texture = json["texture"] as?  [String]
        self.shape = json["shape"] as?  [String]
        
    }
    
}



