//
//  ActionBarButtonItem.swift
//  faer
//
//  Created by pluto on 31.08.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

@IBDesignable

class ActionBarButtonItem: UIBarButtonItem {
    
    @IBInspectable var defaultTint: UIColor?

    @IBInspectable var selectedTint: UIColor?

    var isSelected: Bool = false {
        didSet {
            
            self.tintColor = self.isSelected ? self.selectedTint : self.defaultTint

        }
    }
    
}
