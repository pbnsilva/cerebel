//
//  ItemListLoadOperation.swift
//  faer
//
//  Created by pluto on 18.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation

typealias ItemListLoadOperationCompletionHandlerType = ((ItemList?, Error?) -> ())?

class ItemListLoadOperation: Operation {
    var settings: ItemListSettings
    var completionHandler: ItemListLoadOperationCompletionHandlerType
    var list: ItemList?
    var size: Int
    var offset: Int
    
    init(settings: ItemListSettings, offset: Int, size: Int) {
        self.settings = settings
        self.offset = offset
        self.size = size
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
        ItemList.using(settings: self.settings, atOffset: self.offset, size: self.size) { [weak self] (result, error) in
            guard let _ = self, !self!.isCancelled, error == nil, let _ = result else {
                self?.completionHandler?(nil, error)
                return
            }
            
            DispatchQueue.main.async {
                self?.list = result
                self?.completionHandler?(result, nil)
            }
        }
    }
}
