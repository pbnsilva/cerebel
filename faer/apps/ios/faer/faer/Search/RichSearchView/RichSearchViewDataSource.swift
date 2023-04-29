//
//  RichSearchViewDataSource.swift
//  faer
//
//  Created by pluto on 03.01.19.
//  Copyright © 2019 pluto. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAnalytics
import MapKit

struct RichSearchViewDataSource {
    
    static private func unserialize(data: Data, for parent: UICollectionView) throws -> [RichSection] {
        
        enum ItemType: String {
            case categories
            case map
            case brands
        }
        
        guard
            let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let dic = json as? [String: Any],
            let teaserItems = dic["items"] as? [[String: Any]]
            else {
                throw SerializationError.invalid("Teaser: Bad response, teaser JSON not valid", data)
        }
        
        var sections: [RichSection] = []
        
        for teaserItem in teaserItems {
            
            guard
                let itemTypeRaw = teaserItem["type"] as? String,
                let itemType = ItemType(rawValue: itemTypeRaw)
                else { continue }
            
            switch itemType {
            case .brands:
                do {
                    let brandSpotlight = try BrandSpotlightSection(parent: parent, json: teaserItem)
                    sections.append(brandSpotlight)
                } catch {
                    print(error)
                }
                break;
            case .categories:
                do {
                    let popularCategories = try PopularCategoriesSection(parent: parent, json: teaserItem)
                    sections.append(popularCategories)
                } catch {
                    print(error)
                }
                break;
            case .map:
                do {
                    let mapTeaser = try MapTeaserSection(parent: parent, json: teaserItem)
                    sections.append(mapTeaser)
                } catch {
                    print(error)
                }
                break;
            }
        }
        
        return sections
    }
    
    static func using(location: CLLocation?, parent: UICollectionView, completion: @escaping ([RichSection]?, Error?) -> Void) {
        
        var teaserURL: String = "\(GlobalConfig.faerSearchTeaserHost)?token=\(GlobalConfig.faerSearchAPIKey)&gender=\(User.shared.gender.rawValue)"
        
        if let _ = location {
            teaserURL += "&lat=\(location!.coordinate.latitude)&lon=\(location!.coordinate.longitude)&distance=50km"
        }
        
        let requestUrl = URL(string: teaserURL)!
        var request = URLRequest(url: requestUrl)
        
        request.setValue(Analytics.appInstanceID(), forHTTPHeaderField: "X-User-Id") // used for personalizing feed
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard let data = data, error == nil, let resp = response as? HTTPURLResponse, resp.statusCode == 200 else {
                completion(nil, error)
                return
            }
            
            do {
                
                let result: [RichSection] = try RichSearchViewDataSource.unserialize(data: data, for: parent)
                
                completion(result, nil)
                
            } catch {
                completion(nil, error)
                return
            }
            
            }.resume()
        
    }
    
}

