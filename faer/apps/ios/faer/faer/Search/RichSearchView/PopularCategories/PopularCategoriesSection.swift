//
//  PopularCategoriesSection.swift
//  faer
//
//  Created by pluto on 31.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import UIKit

class PopularCategoriesSection: RichSection {
    
    typealias Category = (category: String, imageURL: URL)
    
    private var dataSource: [Category]?
    
    static func dataSource(from list: [Style]) -> [Category] {
        
        var categoriesToAdd = Set(list.compactMap{$0.items?.first?.annotations?.category?.first?.capitalized})

        return list.compactMap({ (style) in
            guard
                let item = style.items?.first,
                let category = item.annotations?.category?.first?.capitalized,
                let imageURL = item.imageURLs.first,
                categoriesToAdd.contains(category)
                else {
                    return nil
            }
            
            categoriesToAdd.remove(at: categoriesToAdd.firstIndex(of: category)!) // prevent duplicates
            
            return (category, imageURL)
        })
    }
    
    convenience init(parent: UICollectionView?, json: [String: Any]) throws {
        
        guard
            let name = json["name"] as? String,
            let teaserItems = json["items"] as? [[String: Any]]
        else {
            throw SerializationError.missing("Failed to nserialize PopularCategoriesSection json: name or items missing")
        }
        
        self.init(
            name: name,
            cellNibName: PopularCategoryCollectionViewCell.nibName,
            cellReuseIdentifier: PopularCategoryCollectionViewCell.reuseIdentifier,
            parent: parent)

        // get categories
        
        self.dataSource = teaserItems.compactMap {
            
            guard
                let title = $0["title"] as? String,
                let imageRawUrl = $0["image_url"] as? String,
                let imageUrl = URL(string: imageRawUrl)
                else {
                    return nil
            }
            
            return Category(title, imageUrl)
        }
        
        self.totalItems = dataSource?.count
        
        // ensure even number of items due to collectionview layout
        if let _ = self.dataSource {
            if (self.dataSource!.count % 2) != 0 {
                self.dataSource!.removeLast()
                self.totalItems = dataSource!.count
            }
        }
        
    }
    
    convenience init(parent: UICollectionView?, list: [Category]) {
        
        let name = "Popular Categories"
        
        self.init(
            name: name,
            cellNibName: PopularCategoryCollectionViewCell.nibName,
            cellReuseIdentifier: PopularCategoryCollectionViewCell.reuseIdentifier,
            parent: parent)
                
        self.dataSource = list
        
        // ensure even number of items due to collectionview layout
        if (self.dataSource!.count % 2) != 0 {
            self.dataSource!.removeLast()
        }
        
        self.totalItems = dataSource?.count
        
    }
    
    override func segue(at indexPath: IndexPath) {
        guard let _ = self.dataSource, self.dataSource!.indices.contains(indexPath.row) else { return }
        parent?.parentViewController?.performSegue(withIdentifier: CommonSegues.searchResult.rawValue, sender: self.dataSource?[indexPath.row].0)
    }

    override func sizeForItem(minimumInteritemSpacing: CGFloat = 10, maxSize: CGSize) -> CGSize {
        let columns: CGFloat = 2
        let side: CGFloat = (maxSize.width / columns) - (minimumInteritemSpacing / columns)
        return CGSize(width: side, height: side)
    }
    
    override func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell: PopularCategoryCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.itemCell.reuseIdentifier, for: indexPath) as! PopularCategoryCollectionViewCell
        
        guard let content = self.dataSource?[indexPath.row] else {
            return cell
        }
        
        cell.title.text = content.category
        cell.imageView.sd_setImage(with: content.imageURL, completed: nil)
        
        return cell
    }
    
    
}
