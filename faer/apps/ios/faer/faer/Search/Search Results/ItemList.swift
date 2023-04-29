//
//  ItemList
//  faer
//
//  Created by pluto on 28.12.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import UIKit

struct ItemListSimilar {
    
    private (set) var query: String
    private (set) var totalItems: Int // total number of similar items
    private (set) var items: [Item]
    
}

struct ItemList {
    
    //MARK: Types
    struct PropertyKey {
        static let items = "items"
        static let queryAnnotations = "queryAnnotations"
        static let totalItems = "totalItems"
        static let offSet = "offSet"
        static let size = "size"
        static let query = "query"
        static let sessionID = "sessionID"
        static let settings = "setttings"
    }
    
    static let defaultPageSize: Int = 25
    
    private (set) var items: [Item]
    
    private (set) var totalItems: Int // total number of items in the search result
    
    private (set) var queryAnnotations: QueryAnnotations?
    
    private (set) var suggestions: [String]?
    
    private (set) var sessionID: String?
    
    private (set) var similar: ItemListSimilar?
    
    //MARK: Init
    
    init(items: [Item], queryAnnotations: QueryAnnotations?, totalItems: Int = 0) {
        self.items = items
        self.totalItems = totalItems
        self.queryAnnotations = queryAnnotations
    }
    
    init(data: Data) throws {
        
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        guard
            let _ = json,
            let dic = json as? [String:Any],
            let m = dic["matches"] as? [String:Any],
            let _ = m["total"] as? Int,
            let _ = dic["query"] as? [String:Any]
            else {
                throw SerializationError.invalid("ItemList: Bad response, search JSON not valid", json)
        }
        
        self.sessionID = dic["sessionID"] as? String
        // parse query annotations
        self.queryAnnotations = QueryAnnotations(json: dic["query"] as! [String:Any])
        
        // add search suggestions
        self.suggestions = dic["guided"] as? [String]
        
        // parse items if necessary
        self.items = []
        if let items = m["items"] as? [Any] {
            for item in items {
                do {
                    guard let _ = item as? [String:Any] else { throw SerializationError.invalid("ItemList: Bad response, item JSON not valid", item) }
                    let i = try Item(json: (item as! [String:Any]))
                    self.items.append(i)
                } catch {
                    print(error)
                }
            }
        }
        
        self.totalItems = m["total"] as! Int
        
        guard
            let d = dic["similar"] as? [String:Any],
            let query = d["query"] as? String,
            let simMatches = d["matches"] as? [String:Any],
            let total = simMatches["total"] as? Int,
            let _ = simMatches["items"] as? [Any]
            
        else { return }
        
        var si: [Item] = []
        for item in (simMatches["items"] as! [Any]) {
            do {
                guard let _ = item as? [String:Any] else { throw SerializationError.invalid("ItemList: Bad response, similiar item JSON not valid", item) }
                let i = try Item(json: (item as! [String:Any]))
                si.append(i)
            } catch {
                print(error)
            }
        }
        self.similar = ItemListSimilar(query: query, totalItems: total, items: si)

    }
    
    
    // Custom Functions
    /**
     Performs a search with the instance's setting
     
     @return The search result
     */
    
    static func using(settings: ItemListSettings, atOffset: Int, size: Int, completion: @escaping (ItemList?, Error?) -> Void) {
        do {
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }

            let request: URLRequest = try settings.asRequest(offset: atOffset, size: size)
            
            print("request search: offset \(atOffset) size: \(size)")
            
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
                    
                    let result: ItemList = try ItemList(data: data)
                    
            /*       for item in result.items {
                        print("brand: \(item.name), name: \(item.name)")
                    }*/
                    
                    completion(result, nil)
                    
                } catch {
                    completion(nil, error)
                    return
                }
                
                }.resume()
        } catch {
            completion(nil, error)
            return
        }
    }
    
    // Conveinance init using settings
    /**
     Performs a search with the instance's setting
     
     @return The search result
     */
    
    static func using(query: Any, completion: @escaping (ItemListSettings?, ItemList?, Error?) -> Void) {
        
        let settings: ItemListSettings = ItemListSettings(query: query)
        
        ItemList.using(settings: settings, atOffset: 0, size: ItemList.defaultPageSize) { (result, error) in
            completion(settings, result, error)
        }
        
    }

    
    // Conveinance init using settings
    /**
     Performs a search with the instance's setting
     
     @return The search result
     */
    
    static func using(settings: ItemListSettings, completion: @escaping (ItemList?, Error?) -> Void) {
        
        ItemList.using(settings: settings, atOffset: 0, size: ItemList.defaultPageSize) { (result, error) in
            completion(result, error)
        }
        
    }
    
    
    
}
