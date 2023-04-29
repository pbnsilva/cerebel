//
//  NavigationViewTagCollectionViewCell.swift
//  faer
//
//  Created by pluto on 06.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class NavigationViewTagCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier: String = "NavigationViewTagCollectionViewCell"
    
    static let nibName: String = NavigationViewTagCollectionViewCell.reuseIdentifier
    
    private weak var title: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.title = self.viewWithTag(1) as? UILabel
    }
    
    public func set(title: String) {
        self.title?.text = title
        
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.cgColor
    }


}
