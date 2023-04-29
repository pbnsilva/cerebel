//
//  StyleList
//  faer
//
//  Created by pluto on 28.12.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAnalytics

struct StyleList {
    
    private (set) var totalStyles: Int
    
    private (set) var styles: [Style]
    
    private (set) var gender: User.Gender
    
    //MARK: Init
    
    init(styles: [Style], totalStyles: Int = 0, gender: User.Gender) {
        self.styles = styles
        self.totalStyles = totalStyles
        self.gender = gender
    }
    
    init(data: Data, gender: User.Gender) throws {
        
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        guard
            let _ = json,
            let dic = json as? [String:Any],
            let records = dic["records"] as? [[String:Any]],
            let totalStyles = dic["total"] as? Int
            else {
                throw SerializationError.invalid("StyleList: Bad response, feed JSON not valid", json ?? "")
        }
        self.totalStyles = totalStyles
        
        self.styles = records.compactMap { return try? Style(feedJson: $0) }
        
        self.gender = gender
        
    }
    
    
    // Custom Functions
    /**
     Performs a search with the instance's setting
     
     @return The search result
     */
    
    static func using(page: Int, size: Int, completion: @escaping (StyleList?, Error?) -> Void) {
        let size: Int = size
        
        let feedURL: String = "\(GlobalConfig.faerFeedHost)?token=\(GlobalConfig.faerFeedAPIKey)&page=\(page)&size=\(size)&gender=\(User.shared.gender.rawValue)" //TODO refactor into config
        let requestUrl = URL(string: feedURL)!
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
                
                let result: StyleList = try StyleList(data: data, gender: User.shared.gender)
                
                completion(result, nil)
                
            } catch {
                completion(nil, error)
                return
            }
            
        }.resume()
        
    }
    
    
}
