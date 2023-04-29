//
//  RichSection.swift
//  faer
//
//  Created by pluto on 31.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import FirebaseAnalytics

@objc
protocol RichSectionDelegate :class {
    @objc optional func hideMap(requestBy section: RichSection)
    @objc optional func share(sender: UIView, for item: Item)
}

class RichCell: NSObject, NSCoding {
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.nibName, forKey: PropertyKey.nibName)
        aCoder.encode(self.reuseIdentifier, forKey: PropertyKey.reuseIdentifier)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let nibName = aDecoder.decodeObject(forKey: PropertyKey.nibName) as? String,
            let reuseIdentifier = aDecoder.decodeObject(forKey: PropertyKey.reuseIdentifier) as? String
            else {
                return nil
        }
        
        self.init(nibName: nibName, reuseIdentifier: reuseIdentifier)
    }
    
    struct PropertyKey {
        static let nibName = "stores"
        static let reuseIdentifier = "background"
    }

    let nibName: String
    let reuseIdentifier: String
    
    init(nibName: String, reuseIdentifier: String) {
        self.reuseIdentifier = reuseIdentifier
        self.nibName = nibName
    }
    
}

class RichSection: NSObject, NSCoding {

    struct PropertyKey {
        static let itemCell = "stores"
        static let totalItems = "background"
        static let parent = "parent"
        static let section = "section"
        static let isLoading = "isLoading"
        static let name = "name"

    }

    
    internal (set) var itemCell: RichCell
    
    internal (set) var totalItems: Int?
    
    internal var defaultNumberOfItems: Int = 20
    
    internal (set) var name: String
        
    weak var delegate: RichSectionDelegate?
    
    internal var parent: UICollectionView?
    
    var section: Int? // used as external reference by the parent
    
    var isLoading: Bool = false
    
    init(name: String, cellNibName: String, cellReuseIdentifier: String, parent: UICollectionView?) {
        self.name = name
        self.itemCell = RichCell(nibName: cellNibName, reuseIdentifier: cellReuseIdentifier)
        self.parent = parent
    }
    
    // MARK: NSCoding
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let name = aDecoder.decodeObject(forKey: PropertyKey.itemCell) as? String,
            let cell = aDecoder.decodeObject(forKey: PropertyKey.itemCell) as? RichCell
            else {
                return nil
        }
        
        self.init(name: name, cellNibName: cell.nibName, cellReuseIdentifier: cell.reuseIdentifier, parent: aDecoder.decodeObject(forKey: PropertyKey.parent) as? UICollectionView)
        
        self.totalItems = aDecoder.decodeObject(forKey: PropertyKey.totalItems) as? Int
        self.section = aDecoder.decodeObject(forKey: PropertyKey.section) as? Int
        
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: PropertyKey.name)
        aCoder.encode(self.itemCell, forKey: PropertyKey.itemCell)
        aCoder.encode(self.totalItems, forKey: PropertyKey.totalItems)
        aCoder.encode(self.parent, forKey: PropertyKey.parent)
        aCoder.encode(self.section, forKey: PropertyKey.section)
        aCoder.encode(self.isLoading, forKey: PropertyKey.isLoading)
    }
    
    // MARK: Implementation
    
    func updateDataSource() {
        
        // To be override by subclasses
        
    }
    
    func segue(at indexPath: IndexPath) {
        // To be override by subclasses
    }
    
    func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.itemCell.reuseIdentifier, for: indexPath)
        
        return cell
    }
    
    func sizeForItem(minimumInteritemSpacing: CGFloat, maxSize: CGSize) -> CGSize {
        // To be override by subclasses
        return CGSize.zero
    }
    
    func referenceHeightForSectionHeader() -> CGFloat? {
        // To be override by subclasses
        return nil
    }
        
}
