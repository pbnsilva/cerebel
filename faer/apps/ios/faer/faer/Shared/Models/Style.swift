//
//  Style.swift
//  faer
//
//  Created by pluto on 06.10.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import UIKit
import os.log

// MARK: - Style

struct Style: Hashable {
    
    var imageURL: URL
    var sourceName : String
    var sourceProfile : String
    var sourceURL: URL? {
        get {
            return URL.instagramProfile(user: sourceProfile)  //TODO refactor to enum to support other source than instagram
        }
    }
    var items: [Item]?
    var touchAreas: [CGRect]?
    var hashValue: Int {
        
        let s = sourceProfile + sourceName + imageURL.absoluteString
        
        return s.hashValue
    }
    
    
    init(imageURL: URL, sourceName: String, sourceProfile: String, certificate: Certificate, items: [Item]?) {
        self.imageURL = imageURL
        self.sourceName = sourceName
        self.items = items
        self.sourceProfile = sourceProfile
    }
    
    static func ==(lhs: Style, rhs: Style) -> Bool {
        
        guard lhs.sourceProfile == rhs.sourceProfile,
            lhs.sourceName == rhs.sourceName,
            lhs.imageURL == rhs.imageURL
            else { return false }
        return true
    }
    
}

extension Style {
    
    init(feedJson: [String: Any]) throws {
                
        guard let imageUrl = feedJson["image_url"] as? String else {
            throw SerializationError.missing("<image_url> in <style>")
        }
        
        guard let encodedStr = imageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let iurl = URL(rawEncodedUrlStringToBeProxied: encodedStr) else { throw SerializationError.invalid("image_url", imageUrl) }
        self.imageURL = iurl

        // map source
        guard let name = feedJson["title"] as? String else {
            throw SerializationError.missing("item name")
        }
        /*
        guard let source = feedJson["source"] as? [String: Any] else {
            throw SerializationError.missing("source")
        }
        

        guard let profile = source["username"] as? String else {
            throw SerializationError.missing("item username")
        }*/
        
        self.sourceName = name
        self.sourceProfile = ""
        
        // map items
        guard let items = feedJson["items"] as? [Any], items.count > 0 else {
            throw SerializationError.missing("feedJson items")
        }
        self.items = []
        for i in items {
            guard let iSerialized = i as? [String : Any] else {
                throw SerializationError.invalid("feedJson item", i)
            }
            do {
                let item: Item = try Item(json: iSerialized)
                // add style image as to item
                item.style = self
                self.items?.append(item)
            } catch {
                print("style item serialization error", error)
            }
        }
        
    }
    
    
}
