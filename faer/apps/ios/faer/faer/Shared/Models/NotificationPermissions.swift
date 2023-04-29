//
//  NotificationPermissions.swift
//  faer
//
//  Created by pluto on 16.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation


class NotificationPermissions: NSObject, NSCoding {
    
    struct PropertyKey {
        static let wishlistProductOnSale = "wishlistProductOnSale"
        static let brandProductsOnSale = "brandProductsOnSale"
    }
    
    var wishlistProductOnSale: Bool = true
    
    var brandProductsOnSale: Bool = true
    
    override init() {
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.wishlistProductOnSale, forKey: PropertyKey.wishlistProductOnSale)
        aCoder.encode(self.brandProductsOnSale, forKey: PropertyKey.brandProductsOnSale)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.wishlistProductOnSale = aDecoder.decodeBool(forKey: PropertyKey.wishlistProductOnSale)
        self.brandProductsOnSale = aDecoder.decodeBool(forKey: PropertyKey.brandProductsOnSale)
    }
    
}
