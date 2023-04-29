//
//  Models.swift
//  faer
//
//  Created by pluto on 18.08.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import UIKit

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
    case invalid(String)
}

enum RequestError: Error {
    case missing(String)
    case invalid(String, Any)
}

// MARK: - Certificate

class Certificate: NSObject {
    //MARK: NSCoding
    
    override init() {
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
    }
}

// MARK: - Fabric

class Fabric: NSObject {
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        // required
        aCoder.encode(name, forKey: "name")
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String else {
            return nil
        }
        self.init(name: name)
    }

}

extension URL {
    
    static func instagramProfile(user: String) -> URL? {
        return URL(string: "instagram://user?username="+user)
    }
}

extension CGRect {
    func hash() -> Int {
        
        let x = Int(self.origin.x)
        let y = Int(self.origin.y)
        let w = Int(self.size.width)
        let h = Int(self.size.height)
        
        return x << 10 ^ y + w << 10 ^ h
        
    }
}

