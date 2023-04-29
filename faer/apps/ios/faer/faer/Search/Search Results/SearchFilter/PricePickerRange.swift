//
//  PickerRange.swift
//  faer
//
//  Created by pluto on 23.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation

class PriceLowerPicker: PricePickerRange {
    
    override init() {
        super.init()
        data.removeLast() // Remove any
    }
    
}


class PricePickerRange {
    
    fileprivate var data: [String]
    
    private var dataRange: Range<Int>!

    private let pickerStep: Int = 10
    
    private var originalData: [String]
    
    var count: Int {
        get {
            return data.count
        }
    }
    
    init() {
        self.data = []
        data.append("1")
        for i in stride(from: self.pickerStep, to: 500, by: self.pickerStep) {
            data.append(String(i))
        }
        data.append(String(600))
        data.append(String(700))
        data.append(String(800))
        data.append(String(900))
        data.append(String(1000))
        data.append(String(2000))
        data.append(String(2500))
        data.append("Any")
        
        self.dataRange = 0..<2500
        
        self.originalData = self.data
    }
    
    convenience init(endPrice: Int) {
        self.init()
        if let e = self.data.index(of: String(endPrice)) {
            self.data = Array(self.data[..<e])
        }
    }
    
    convenience init(startPrice: Int) {
        self.init()
        if let s = self.data.index(of: String(startPrice)) {
            self.data = Array(self.data[(s+1)...])
        }
    }
    
    
    func rowFor(_ price: Int) -> Int {
        
        if price > 2500 {
            return self.data.indices.last!
        }
        
        var row: Int = 0

        for (index, element) in self.data.enumerated() {
            guard let _ = Int(element) else { continue }
            if price <= Int(element)! {
                row = index
                break
            }
        }
        
        return row
    }
    
    func labelFor(price: Int) -> String {
        return self.labelFor(row: self.rowFor(price))
    }
    
    func labelFor(row: Int) -> String {
        return data[row]
    }
    
    func priceFor(_ row: Int) -> Int {
        if self.data[row] == "Any" {
            return ItemListSettings.allPriceRange.upperBound
        }
        if self.data[row] == "1" {
            return 0
        }
        return Int(self.data[row])!
    }
    
}
