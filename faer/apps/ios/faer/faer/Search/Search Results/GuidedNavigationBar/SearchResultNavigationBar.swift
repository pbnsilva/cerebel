//
//  SearchResultNavigationBar.swift
//  faer
//
//  Created by pluto on 05.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class SearchResultNavigationBar: UINavigationBar {
        
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.commonInit()

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    private func commonInit() {
        
        // remove bottom shadow
        let img: UIImage = UIImage()
        
        self.shadowImage = img
        
        self.setBackgroundImage(img, for: UIBarMetrics.default) // required to make shadow disappear on 10.3.1
    }
    
}
