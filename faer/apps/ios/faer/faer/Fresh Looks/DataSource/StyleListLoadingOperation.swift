//
//  DataLoadingOperation.swift
//  faer
//
//  Created by pluto on 17.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation

typealias StyleListLoadOperationCompletionHandlerType = ((StyleList?, Error?) -> ())?

class StyleListLoadOperation: Operation {
    var completionHandler: StyleListLoadOperationCompletionHandlerType
    var list: StyleList?
    var size: Int
    var page: Int
    
    init(section: Int, size: Int) {
        self.page = section + 1 // API starts count at 1, not 0
        self.size = size
    }
    
    override func main() {
        
        if isCancelled {
            return
        }
        
        StyleList.using(page: self.page, size: self.size) { [weak self] (list, error) in
                self?.list = list
                self?.completionHandler?(list, error)
        }
    }
}
