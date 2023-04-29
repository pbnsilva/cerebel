//
//  StoreAnnotation.swift
//  faer
//
//  Created by pluto on 06.11.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import MapKit


class StoreAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
    
    convenience init(store: Store) {
        
        self.init(coordinate: store.location.coordinate, title: store.name, subtitle: store.address ?? store.postalCode)
        
    }
    
}
