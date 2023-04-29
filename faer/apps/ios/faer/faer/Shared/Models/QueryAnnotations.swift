//
//  Annotations.swift
//  faer
//
//  Created by pluto on 28.12.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation

class QueryAnnotations: NSObject, NSCoding {
    
    //MARK: Types
    struct PropertyKey {
        static let intent = "category"
        static let entities = "color"
    }
    
    var entities: [Entity]
    var intent: String
    
    var flatOriginal: String {
        get {
            let sorted: [Entity] = self.entities.sorted(by: {
                if let _ = $0.start {
                    return $0.start! < $1.start!
                }
                return false
            })
            return sorted.compactMap({$0.original}).joined(separator: " ")
        }
    }
    
    init(intent: String, entities: [Entity]) {
        self.intent = intent
        self.entities = entities
    }
    
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        // optionals
        aCoder.encode(entities, forKey: PropertyKey.entities)
        aCoder.encode(intent, forKey: PropertyKey.intent)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let _ = aDecoder.decodeObject(forKey: PropertyKey.entities) as? [Entity],
            let _ = aDecoder.decodeObject(forKey: PropertyKey.intent) as? String
            else {
                return nil
        }
        
        self.init(intent: aDecoder.decodeObject(forKey: PropertyKey.intent) as! String, entities: aDecoder.decodeObject(forKey: PropertyKey.entities) as! [Entity])
        
    }
}

class Entity: NSObject, NSCoding {
    
    //MARK: Types
    struct PropertyKey {
        static let type = "type"
        static let value = "value"
        static let start = "start"
        static let end = "end"
        static let original = "original"
        static let confidence = "confidence"
    }
    
    var type: String
    var value: String
    var start: Int?
    var end: Int?
    var original: String?
    var confidence: Float?
    
    init (type: String, value: String, start: Int?, end: Int?, original: String?, confidence: Float?) {
        self.type = type
        self.value = value
        self.start = start
        self.end = end
        self.original = original
        self.confidence = confidence
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        // optionals
        aCoder.encode(type, forKey: PropertyKey.type)
        aCoder.encode(value, forKey: PropertyKey.value)
        aCoder.encode(start, forKey: PropertyKey.start)
        aCoder.encode(end, forKey: PropertyKey.end)
        aCoder.encode(original, forKey: PropertyKey.original)

    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let type = aDecoder.decodeObject(forKey: PropertyKey.type) as? String,
            let value = aDecoder.decodeObject(forKey: PropertyKey.value) as? String
            else {
                return nil
        }
        
        self.init(type: type,
                  value: value,
                  start: aDecoder.decodeObject(forKey: PropertyKey.start) as? Int,
                  end: aDecoder.decodeObject(forKey: PropertyKey.end) as? Int,
                  original: aDecoder.decodeObject(forKey: PropertyKey.original) as? String,
                  confidence: aDecoder.decodeObject(forKey: PropertyKey.confidence) as? Float)
    }
    
}

// Init from JSON
extension Entity {
    
    convenience init?(json: [String: Any]) {
        
        guard
            let _ = json["type"] as? String,
            let _ = json["value"] as? String
            else {
                return nil
        }

        
        self.init(type: json["type"] as! String,
                  value: json["value"] as! String,
                  start: nil,
                  end: nil,
                  original: nil,
                  confidence: nil)
        self.start = json["start"] as? Int
        self.end = json["end"] as? Int
        self.confidence = json["confidence"] as? Float
        self.original = json["original"] as? String
    }
}


// Init from JSON
extension QueryAnnotations {
    
    convenience init?(json: [String: Any]) {
        
        guard
            let _ = json["intent"] as? String,
            let entitiesRaw = json["entities"] as? [Any],
            !entitiesRaw.isEmpty
            else {
                return nil
        }
        
        self.init(intent: json["intent"] as! String, entities: [])

        for entity in entitiesRaw {
            guard let _ = entity as? [String: Any],
                let e = Entity(json:(entity as! [String: Any]))
                else {
                    continue
            }
            self.entities.append(e)
        }
                
    }
}
