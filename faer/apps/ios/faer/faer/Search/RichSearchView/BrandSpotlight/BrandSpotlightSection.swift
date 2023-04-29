//
//  BrandSpotlightSection.swift
//  faer
//
//  Created by pluto on 31.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import UIKit

class BrandSpotlightSection: RichSection {
    
    typealias TitleItems = [(title: String, items: [Item]?)]
    
    var dataSource: TitleItems? {
        willSet(newValue) {
            self.totalItems = newValue?.count
        }
    }
        
    convenience init(parent: UICollectionView?) {
        
        let name: String = "Brand Spotlight"
        
        self.init(
            name: name,
            cellNibName: BrandSpotlightItemCollectionViewCell.nibName,
            cellReuseIdentifier: BrandSpotlightItemCollectionViewCell.reuseIdentifier,
            parent: parent)
                        
    }
    
    convenience init(parent: UICollectionView?, json: [String: Any]) throws {
        
        guard
            let name = json["name"] as? String,
            let teaserItems = json["items"] as? [[String: Any]]
            else {
                throw SerializationError.missing("Failed to nserialize BrandSpotlightSection json: name or items missing")
        }
        
        self.init(
            name: name,
            cellNibName: BrandSpotlightItemCollectionViewCell.nibName,
            cellReuseIdentifier: BrandSpotlightItemCollectionViewCell.reuseIdentifier,
            parent: parent)
        
        // get title items
        
        var titleItems: TitleItems = []
        
        for teaser in teaserItems {
            guard
                let title = teaser["title"] as? String,
                let products = teaser["products"] as? [[String: Any]]
                else {
                    continue
            }
            
            let items: [Item] = products.compactMap{ return try? Item(json: $0) }
            
            titleItems.append((title, items))
            // [(title: String, items: [Item]?)]
            
        }
        
        self.dataSource = titleItems
        
        self.totalItems = self.dataSource?.count

    }
    
    //MARK: NSCoding
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.dataSource, forKey: PropertyKey.dataSource)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let dataSource = aDecoder.decodeObject(forKey: PropertyKey.dataSource) as? TitleItems
            else {
                return nil
        }
        self.init(parent: aDecoder.decodeObject(forKey: PropertyKey.parent) as? UICollectionView)
        self.dataSource = dataSource
    }
    
    struct PropertyKey {
        static let dataSource = "dataSource"
    }

    
    static func itemsBySameBrand(brands: [String], completion: @escaping (TitleItems?, Error?) -> Void) {
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        let maxItemsPerBrand: Int = 10
        
        let jsonBody: [String: Any] = [
            "offset": 0,
            "showSimilar": true,
            "size": 0,
            "filters": [
                "gender": User.shared.gender.rawValue,
                "brand": brands
            ],
            "aggregations": [
                "count": [
                    "fields": ["brand"],
                    "topHits": maxItemsPerBrand
                ]
            ]
        ]
        
        // serialize data
        
        let requestData: Data? = try? JSONSerialization.data(withJSONObject: jsonBody, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        
        guard let _ = requestData else {
            completion(nil, nil)
            return
        }
        // perform request
        var request = URLRequest(url: URL(string: "\(GlobalConfig.faerSearchHost)/text")!)
        request.httpBody = requestData
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "X-Cerebel-Token": GlobalConfig.faerSearchAPIKey,
            "Accept": "application/json"
        ]
        
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            #if DEBUG
            // print("itemlist using", response ?? "", error ?? "", String(data: data ?? Data(), encoding: .utf8))
            #endif
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard let data = data, error == nil, let resp = response as? HTTPURLResponse, resp.statusCode == 200 else {
                completion(nil, error)
                return
            }
            
            do {
                
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard
                    let dic = json as? [String: Any],
                    let aggregations = dic["aggregations"] as? [String: Any],
                    let count = aggregations["count"] as? [String: Any],
                    let brands = count["brand"] as? [Any]
                    else {
                        completion(nil, nil)
                        return
                }
                
                let result: TitleItems = brands.compactMap({ brand in
                    guard
                        let dic = brand as? [String: Any],
                        let title = dic["value"] as? String,
                        let topHits = dic["topHits"] as? [[String: Any]]
                        
                        else { return nil }
                    
                    let items: [Item] = topHits.compactMap { return try? Item(json: $0) }
                    
                    return (title.capitalized, items)
                })
                
                completion(result, nil)
                
            } catch {
                completion(nil, error)
                return
            }
            
            }.resume()
    }
    
    override func sizeForItem(minimumInteritemSpacing: CGFloat = 10, maxSize: CGSize) -> CGSize {
        return CGSize(width: maxSize.width, height: maxSize.height * 0.6)
    }
    
    override func segue(at indexPath: IndexPath) {
        // To be override by subclasses
        guard
            let _ = self.dataSource,
            self.dataSource!.indices.contains(indexPath.row),
            let item = self.dataSource?[indexPath.row].items?.first
            else { return }
        
        parent?.parentViewController?.performSegue(withIdentifier: CommonSegues.brandProfile.rawValue, sender: item)
    }
    
    // uses closure completion when done
    static func loadDataSource(using brands: [String], completion: @escaping (TitleItems?, Error?) -> Void) {
        
        BrandSpotlightSection.itemsBySameBrand(brands: brands, completion: { (brandItems, error) in
            
            completion(brandItems,error)
           
        })

    }
        
    override func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell: BrandSpotlightItemCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.itemCell.reuseIdentifier, for: indexPath) as! BrandSpotlightItemCollectionViewCell
      
        if
            self.dataSource?.indices.contains(indexPath.row) ?? false,
            let content = self.dataSource?[indexPath.row]
        {
            cell.configure(title: content.title, items: content.items ?? [])
        }
        
        cell.delegate = self

        return cell
    }
    
}


extension BrandSpotlightSection: BrandSpotlightItemCollectionViewCellDelegate {
    
    func tapped(item: Item) {
        Log.Tap.item(view: .BrandSpotlight, item: item)
        parent?.parentViewController?.performSegue(withIdentifier: CommonSegues.PDP.rawValue, sender: item)
    }
    
    func tapped(brand: Item) {
        parent?.parentViewController?.performSegue(withIdentifier: CommonSegues.brandProfile.rawValue, sender: brand)
    }
    
    func share(sender: UIView, item: Item) {
        self.delegate?.share?(sender: sender, for: item)
    }
    
}
