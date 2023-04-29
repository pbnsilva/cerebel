//
//  SearchResultViewDataSource.swift
//  faer
//
//  Created by pluto on 18.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation


struct SearchResultViewDataSource {
    
    typealias Section = Int
    
    let totalNumberOfSections: Int // total number of sections
    
    let totalNumberOfItems: Int // total number of items
    
    var sectionItems: [Section: [Item]?]
    
    private let sectionSize: Int
    
    init(list: ItemList, sectionSize: Int) {
        
        self.sectionItems = [0: list.items]
        self.sectionSize = sectionSize
        
        if list.totalItems < sectionSize {
            // there is an API issue where list.totalItems exceeds the actual number of items available from the API.
            // this fix only covers the case when all items can be fetched with a single request
            self.totalNumberOfItems = list.items.count
        } else {
            self.totalNumberOfItems = list.totalItems
        }
        
        // calc numberOfSection
        if totalNumberOfItems == 0 {
            totalNumberOfSections = 0
        } else {
            let number: Int = totalNumberOfItems / sectionSize
            totalNumberOfSections = (totalNumberOfItems % sectionSize) != 0 ? number + 1 : number
        }
    
    }
    
    func offsetForSection(_ section: Int) -> Int {
        
        return sectionSize * section
        
    }
    
    func numberOfItems(section: Int) -> Int {
        
        guard totalNumberOfItems > 0 else {
            return 0
        }
        
        // is last section
        let reminder: Int = totalNumberOfItems % sectionSize
        if (reminder != 0) && (section == (totalNumberOfSections - 1)) {
            return reminder
        }
        
        return sectionSize
        
    }
    
}
