//
//  ProductDetailAccessoryCollectionViewCell.swift
//  faer
//
//  Created by venus on 05.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class ProductDetailAccessoryCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifer: String = "ProductDetailAccessoryCollectionViewCell"
    static let nibName: String = "ProductDetailAccessoryCollectionViewCell"
    
    private weak var accessoryDescription: UILabel?
    
    private weak var title: UILabel?
    
    private weak var bottomSeperator: UIView?
    
    private weak var topSeperator: UIView?
    
    var hasbottomSeperator: Bool = false {
        didSet {
            self.bottomSeperator?.isHidden = !self.hasbottomSeperator
        }
    }
    
    var hasTopSeperator: Bool = false {
        didSet {
            self.topSeperator?.isHidden = !self.hasTopSeperator
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.title = self.viewWithTag(1) as? UILabel
        
        self.accessoryDescription = self.viewWithTag(2) as? UILabel
        
        self.bottomSeperator = self.viewWithTag(3)
        
        self.topSeperator = self.viewWithTag(4)
        
        self.bottomSeperator?.isHidden = true
        self.topSeperator?.isHidden = true
        
    }
    
    func configure(title: String, description: String) {
        
        self.title?.text = title
        
        self.accessoryDescription?.text = description
        
        self.layoutSubviews()
        self.setNeedsLayout()
        self.invalidateIntrinsicContentSize()
        
    }
    
}
