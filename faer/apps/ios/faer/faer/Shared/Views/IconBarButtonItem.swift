//
//  IconBarButtonItem
//  faer
//
//  Created by pluto on 20.06.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class IconBarButtonItem: UIBarButtonItem {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    
    func commonInit() {
        // setup back button
        let barBtntextAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font : UIFont(name: StyleGuide.font.icon.rawValue, size: StyleGuide.fontHeadlineSize*1.2)!,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.baselineOffset: -2 // to align with title
        ]
        
        self.setTitleTextAttributes(barBtntextAttributes, for: .normal)
        self.setTitlePositionAdjustment(UIOffset(horizontal: 0, vertical: 50), for: UIBarMetrics.default)

    }

}
