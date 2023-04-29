//
//  SearchAutocomplete.swift
//  faer
//
//  Created by pluto on 06.08.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation


//
//  ItemList
//  faer
//
//  Created by pluto on 28.12.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import UIKit

struct Suggestion {
    
    var value: String
    var offset: Int?
    var length: Int?
    
    init(data: [String:Any]) throws {
        guard
            let _ = data["value"] as? String
            else {
                throw SerializationError.invalid("Suggestion: Bad response, JSON not valid", data)
        }
        
        self.value = data["value"] as! String
        self.offset = data["offset"] as? Int
        self.length = data["length"] as? Int
    }
    
}

struct SearchAutocomplete {
    
    //MARK: Types
    
    private (set) var items: [Suggestion]!
    
    //MARK: Init
    
    init(items: [Suggestion]) {
        self.items = items
    }
    
    init(data: Data) throws {
        
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        guard
            let _ = json,
            let dic = json as? [String:Any],
            let suggestionsArray = dic["suggestions"] as? [[String: Any]]
            else {
                throw SerializationError.invalid("ItemList: Bad response, search JSON not valid", json!)
        }
        
        // parse items if necessary
        self.items = suggestionsArray.compactMap{ try? Suggestion(data: $0) }
        
        
        print(self.items)
        
        
        /*
        self.items = []
        for s in suggestionsArray {
            let suggestion: Suggestion = try Suggestion(data: s as! [String: Any])
            self.items?.append(suggestion)
        }*/
    }
    
    
    // Custom Functions
    /**
     Performs a search with the instance's setting
     
     @return The search result
     */
    
}

class SearchAutoCompleteService: NSObject {
    
    static private func clearCacheIfNeeded(for request: URLRequest) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd LLL yyyy HH:mm:ss zzz" // http://userguide.icu-project.org/formatparse/datetime

        guard
            let cachedResponse = URLCache.shared.cachedResponse(for: request),
            let response = cachedResponse.response as? HTTPURLResponse,
            let date = response.allHeaderFields["Date"] as? String,
            let responseDate = dateFormatter.date(from: date)
            else {
                return
        }

        let cacheExpirationTime: TimeInterval = 86400 // expire after 24h
        if
            abs(responseDate.timeIntervalSinceNow) > cacheExpirationTime,
            Network.shared.isReachable()
        {
            URLCache.shared.removeCachedResponse(for: request)
        }
        
    }
    
    static func suggestions(size: Int, completion: @escaping (SearchAutocomplete?, Error?) -> Void) {
        
        let autocompleteURL: String = "\(GlobalConfig.faerAutoCompleteHost)?token=\(GlobalConfig.faerAutoCompleteAPIKey)&size=\(size)" //TODO refactor into config
        let requestUrl = URL(string: autocompleteURL)!
        
        let request = URLRequest(url: requestUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
      //  SearchAutoCompleteService.clearCacheIfNeeded(for: request)
                
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard let data = data, error == nil, let resp = response as? HTTPURLResponse, resp.statusCode == 200 else {
                completion(nil, error)
                return
            }
            
            do {
                
                let result: SearchAutocomplete = try SearchAutocomplete(data: data)
                
                completion(result, nil)
                
            } catch {
                completion(nil, error)
                return
            }
            
            }.resume()
        
    }
    
    static func using(text: String, size: Int, completion: @escaping (SearchAutocomplete?, Error?) -> Void) {
        
        guard let urlEncodedText: String = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return }
        
        let autocompleteURL: String = "\(GlobalConfig.faerAutoCompleteHost)?token=\(GlobalConfig.faerAutoCompleteAPIKey)&size=\(size)&q=\(urlEncodedText)" //TODO refactor into config
        let requestUrl = URL(string: autocompleteURL)
        let request = URLRequest(url: requestUrl!)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard let data = data, error == nil, let resp = response as? HTTPURLResponse, resp.statusCode == 200 else {
                completion(nil, error)
                return
            }
            
            do {
                
                let result: SearchAutocomplete = try SearchAutocomplete(data: data)
                
                completion(result, nil)
                
            } catch {
                completion(nil, error)
                return
            }
            
            }.resume()
        
    }
    
    
    
}

//MARK: URLSessionsDelegate
extension SearchAutoCompleteService: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        completionHandler(proposedResponse)
        return
    }
    
}
