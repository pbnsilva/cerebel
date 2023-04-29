//
//  ProductDetailAboutCollectionViewCell.swift
//  faer
//
//  Created by pluto on 05.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class ProductDetailAboutCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifer: String = "ProductDetailAboutCollectionViewCell"
    static let nibName: String = ProductDetailAboutCollectionViewCell.reuseIdentifer
    
    private weak var about: UITextView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.about = self.viewWithTag(1) as? UITextView
        
    }
    
    func configure(description: String) {
        
        let fontSize: CGFloat = 16
        // IB bug: Manuall set font, as open Sans is not recognized properly when using attributedText
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 1             // Paragraph Spacing
        paragraphStyle.lineSpacing = 1.3 // Line Spacing
        
        // attributed Title
        let textAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font : UIFont(name: StyleGuide.fontBody, size: fontSize)!,
            NSAttributedString.Key.paragraphStyle : paragraphStyle
        ]
        
        self.about?.attributedText = NSMutableAttributedString(string: description, attributes: textAttributes)
        
        self.layoutSubviews()
        self.setNeedsLayout()
        
    }
    
}
