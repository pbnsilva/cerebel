//
//  Annotations.swift
//  faer
//
//  Created by pluto on 28.12.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation

typealias Prices = [Price]

class Price: NSObject, NSCoding, NSCopying, Decodable {


    //MARK: Types
    struct PropertyKey {
        static let value = "value"
        static let originalValue = "originalValue"
        static let localeIdentifier = "localeIdentifier"
    }
    
    static let missingValue: Double = 20000 // used for migration of old pricing model
    
    var value: Double
    var originalValue: Double?
    var localeIdentifier: String
    
    var currencySymbol: String {
        get {
            var currencySymbol: String = ""
            for id in GlobalConfig.supportedLocaleIdentifiers {
                let locale = Locale(identifier: id)
                if locale.identifier == self.localeIdentifier {
                    currencySymbol = locale.currencySymbol ?? ""
                }
            }
            return currencySymbol
        }
    }
    
    var currencyCode: String {
        get {
            var currencyCode: String = ""
            for id in GlobalConfig.supportedLocaleIdentifiers {
                let locale = Locale(identifier: id)
                if locale.identifier == self.localeIdentifier {
                    currencyCode = locale.currencyCode?.lowercased() ?? ""
                }
            }
            return currencyCode
        }
    }
    
    init(value: Double, localeIdentifier: String) {
        
        self.value = value
        self.localeIdentifier = localeIdentifier
        
    }
    
    convenience init(value: Double, originalValue: Double?, localeIdentifier: String) {
        self.init(value: value, localeIdentifier: localeIdentifier)
        self.originalValue = originalValue
    }
    
    static func locale(for currencyCode: String) -> Locale? {
        for id in GlobalConfig.supportedLocaleIdentifiers {
            let locale = Locale(identifier: id)
            if locale.currencyCode?.lowercased() == currencyCode.lowercased() {
                return locale
            }
        }
        return nil
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(value, forKey: PropertyKey.value)
        aCoder.encode(originalValue, forKey: PropertyKey.originalValue)
        aCoder.encode(localeIdentifier, forKey: PropertyKey.localeIdentifier)
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard
            let value = aDecoder.decodeDouble(forKey: PropertyKey.value) as Double?,
            let locale = aDecoder.decodeObject(forKey: PropertyKey.localeIdentifier) as? String
        else {
            return nil
        }
        
        self.init(value: value, localeIdentifier: locale)
        
        self.originalValue = aDecoder.decodeObject(forKey: PropertyKey.originalValue) as? Double
        
    }
    
    //MARK: NSCopying
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Price(value: value, originalValue: originalValue, localeIdentifier: localeIdentifier)
        return copy
    }
    
}



