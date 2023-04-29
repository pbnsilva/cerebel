//
//  OutlinedLabel
//  faer
//
//  Created by pluto on 22.08.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit

class OutlinedLabel: CopyableLabel {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 1
        self.layer.shadowOpacity = 0.4
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        guard let _ = self.text else { return }
        
        self.setAttributedTitle(title: self.text!)
        
    }

    //MARK: - Custom Functions
    
    func setAttributedTitle(title: String) {
        self.text = nil
        self.attributedText = self.attributedTitle(forString: title)
    }
    
    func setAttributedTitle(title: NSMutableAttributedString, alpha: CGFloat = 1) {
        self.text = nil
                
        let strokeTextAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.strokeColor: UIColor.black.withAlphaComponent(alpha),
            NSAttributedString.Key.strokeWidth : -1,
            NSAttributedString.Key.font : self.font
        ]

        title.addAttributes(strokeTextAttributes, range: NSMakeRange(0, title.length))
        self.attributedText = title
    }

    
    private func attributedTitle(forString: String) -> NSAttributedString {
        
        let strokeTextAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.strokeColor: UIColor.black,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.strokeWidth : -1,
            NSAttributedString.Key.font : self.font
        ]
        
        return NSMutableAttributedString(string: forString, attributes: strokeTextAttributes)
    }
    
}

