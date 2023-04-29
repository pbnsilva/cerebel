//
//  ProductDetailCollectionViewController.swift
//  faer
//
//  Created by pluto on 02.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import CoreLocation

extension ProductDetailCollectionViewController {
    
    
    private func itemsBySameBrand(completion: @escaping ([Item], Error?) -> Void) {
        
        var settings: ItemListSettings = ItemListSettings()
        settings.brands = [self.item!.brand]
        ItemList.using(settings: settings, atOffset: 0, size: self.maxNumberOfRecommendations) { (result, error) in
            guard error == nil, let _ = result else { completion([], error); return }
            var finalRecos: [Item] = result!.items
            finalRecos = finalRecos.filter { $0 != self } // always remove parent duplicates
            finalRecos = finalRecos.unique() // remove any other duplicates
            completion(finalRecos, nil)
        }
    }
    
    private func itemsWithSameColor(completion: @escaping ([Item], Error?) -> Void) {
        guard
            let _ = self.item?.annotations,
            let color: String = self.item?.annotations!.color?.first else {
                return completion([], nil) }
        
        var settings: ItemListSettings = ItemListSettings()
        settings.color = [color]
        
        ItemList.using(settings: settings, atOffset: 0, size: self.maxNumberOfRecommendations) { (result, error) in

            guard error == nil, let _ = result else { completion([], error); return }
            var finalRecos: [Item] = result!.items
            finalRecos = finalRecos.filter { $0 != self } // always remove parent duplicates
            finalRecos = finalRecos.unique() // remove any other duplicates
            completion(finalRecos, nil)
        }
        
    }
    
    private func itemsBySameCategory(completion: @escaping ([Item], Error?) -> Void) {
        guard
            let _ = self.item?.annotations,
            let cat: String = self.item?.annotations!.category?.first else {
                return completion([], nil) }
        
        let settings: ItemListSettings = ItemListSettings(query: cat)
        
        ItemList.using(settings: settings, atOffset: 0, size: self.maxNumberOfRecommendations) { (result, error) in

            guard error == nil, let _ = result else { completion([], error); return }
            var finalRecos: [Item] = result!.items
            finalRecos = finalRecos.filter { $0 != self } // always remove parent duplicates
            finalRecos = finalRecos.unique() // remove any other duplicates
            completion(finalRecos, nil)
        }
        
    }
    
    func loadProductRecommendations() {
        
        // query for recommendations
        let group: DispatchGroup = DispatchGroup()
        //  items by brand
        
        var recos: [Section: [Item]] = [:]
        
        group.enter()
        self.itemsBySameBrand { (items, error) in
            recos[Section.moreBySameBrand] = items
            group.leave()
        }
        
        // items by category
        group.enter()
        self.itemsBySameCategory { (items, error) in
            recos[Section.moreBySameCategory] = items
            group.leave()
        }
        
        // items by same color
        group.enter()
        self.itemsWithSameColor { (items, error) in
            recos[Section.moreWithSameColor] = items
            group.leave()
        }
        group.notify(queue: .main) {

            DispatchQueue.main.async {
                guard recos.count > 0 else { return }
                
                var seenStringValues = Set<Item>()
                var uniqueRecos: [Section: [Item]] = [:]

                for (key, values) in recos {
                    guard values.count > 0 else { continue }
                    uniqueRecos[key] = values.filter{ seenStringValues.insert($0).inserted }
                }
                
                self.configureProductRecommendations(recos: uniqueRecos)
            }
            
        }
        
    }
    
    
}
