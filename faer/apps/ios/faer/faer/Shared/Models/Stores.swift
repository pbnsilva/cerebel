//
//  Stores.swift
//  faer
//
//  Created by pluto on 06.11.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

struct Stores {
    
    static func using(location: CLLocation, completion: @escaping ([Store]?, Error?) -> Void) {
        
        struct StoresService: Decodable {
            var aggregations: Aggregations
            
            struct Aggregations: Decodable {
                var count: Count
                
                struct Count: Decodable {
                    var brand: [Aggregation]
                    
                    struct Aggregation: Decodable {
                        var value: String
                        var count: Int
                        var topHits: [TopHit]
                        
                        struct TopHit: Decodable {
                            var stores: [Store]
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        let jsonBody: [String: Any] = [
            "filters": [
                "store_locations": [
                    "distance": "50km",
                    "location": [
                        "lat": location.coordinate.latitude,
                        "lon":  location.coordinate.longitude
                    ]
                ]
            ],
            "aggregations": [
                "count": [
                    "fields": ["brand"],
                    "topHits": 1
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
                
                let decoder = JSONDecoder()
                let storeService = try decoder.decode(StoresService.self, from: data)
                                
                let stores: [Store] = storeService.aggregations.count.brand.flatMap { $0.topHits }.flatMap { $0.stores }
                
                completion(Array(Set(stores)), nil)
                return
                
            } catch {
                completion(nil, error)
                return
            }
            
            }.resume()
    }
}
