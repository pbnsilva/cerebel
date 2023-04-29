//
//  OutlinedButton.swift
//  faer
//
//  Created by pluto on 22.08.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit

extension UIColor {
    var inverted: UIColor {
        var a: CGFloat = 0
        
        var white: CGFloat = 0
        if self.getWhite(&white, alpha: &a) {
            return UIColor(white: 1.0 - white, alpha: a)
        }
        
        var h:CGFloat = 0, s:CGFloat = 0, b:CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
        }

        var r:CGFloat = 0, g:CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
        
        return self

    }
}

class OutlinedButton: UIButton {
    
    override public var isSelected: Bool {
        willSet(selectedValue) {
            // Do whatever you want
            guard let _ = self.titleLabel, let _ = self.titleLabel!.text else { return }
            if selectedValue {
                // make title outlined
                let strokeTextAttributes:[NSAttributedString.Key : Any] = [
                    NSAttributedString.Key.strokeColor: self.titleColor(for: .selected)!.inverted.withAlphaComponent(0.8),
                    NSAttributedString.Key.foregroundColor: self.titleColor(for: .selected) as Any,
                    NSAttributedString.Key.strokeWidth : -1,
                    NSAttributedString.Key.font : self.titleLabel!.font
                ]
                
                self.setAttributedTitle(NSMutableAttributedString(string: self.titleLabel!.text!, attributes: strokeTextAttributes), for: .normal)
            } else {
                // make title outlined
                let strokeTextAttributes:[NSAttributedString.Key : Any] = [
                    NSAttributedString.Key.strokeColor: self.currentTitleColor.inverted,
                    NSAttributedString.Key.foregroundColor: self.currentTitleColor,
                    NSAttributedString.Key.strokeWidth : -1,
                    NSAttributedString.Key.font : self.titleLabel!.font
                ]
                
                self.setAttributedTitle(NSMutableAttributedString(string: self.titleLabel!.text!, attributes: strokeTextAttributes), for: .normal)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
         self.commonInit()
    }
    
    func commonInit() {
        guard let _ = self.titleLabel, let _ = self.titleLabel!.text else { return }
        
        // make title outlined
        let strokeTextAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.strokeColor: self.currentTitleColor.inverted,
            NSAttributedString.Key.foregroundColor: self.currentTitleColor,
            NSAttributedString.Key.strokeWidth : -1,
            NSAttributedString.Key.font : self.titleLabel!.font
        ]
        
        self.setAttributedTitle(NSMutableAttributedString(string: self.titleLabel!.text!, attributes: strokeTextAttributes), for: .normal)
        
        self.isExclusiveTouch = true
        
    }
    
}
