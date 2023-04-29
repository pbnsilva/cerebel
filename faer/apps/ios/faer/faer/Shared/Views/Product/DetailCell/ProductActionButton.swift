//
//  ProductActionButton.swift
//  faer
//
//  Created by pluto on 22.08.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

@IBDesignable
class ProductActionButton: UIButton {
    
    @IBInspectable var solidImage: UIImage? {
        didSet {
            self.setImage(solidImage, for: .solid)
            
        }
    }
    
    var isSolid: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    override var state: UIControl.State {
        get {
            return isSolid ? UIControl.State(rawValue: super.state.rawValue | UIControl.State.solid.rawValue) : super.state
        }
    }
    
}

private extension UIControl.State {
    static let solid = UIControl.State(rawValue: 1 << 16)
}
