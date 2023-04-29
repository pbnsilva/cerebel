//
//  BrandHeaderCollectionViewCell.swift
//  faer
//
//  Created by pluto on 01.02.19.
//  Copyright © 2019 pluto. All rights reserved.
//

import UIKit

class BrandHeaderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var priceRange: UILabel!
    
    @IBOutlet weak var story: UITextView!
    
    static let reuseIdentifier: String = "BrandHeaderCollectionViewCell"
    
    static let nibName: String = BrandHeaderCollectionViewCell.reuseIdentifier

    @IBOutlet weak var storyTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var lineTopConstraint: NSLayoutConstraint!
    
    private let storyTopConstraintDefaultConstant: CGFloat = 20
    private let lineTopConstraintDefaultConstant: CGFloat = 15

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // remove padding and margin
        self.story.textContainerInset = UIEdgeInsets.zero
        self.story.textContainer.lineFragmentPadding = 0
    }
    
    private func setStory(for brand: Brand) {
        
        guard let story = brand.story else {
            self.story.isHidden = true
            self.storyTopConstraint.constant = 0
            self.lineTopConstraint.constant = 0

            return
        }
        
        self.storyTopConstraint.constant = self.storyTopConstraintDefaultConstant
        self.lineTopConstraint.constant = self.lineTopConstraintDefaultConstant
        
        self.story.isHidden = false
        
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
        
        self.story.attributedText = NSMutableAttributedString(string: story, attributes: textAttributes)
        
    }
    
    func configure(brand: Brand) {
        self.title.text = brand.name
        self.priceRange.text = brand.priceRange
        if let _ = brand.location {
            self.location.text = brand.location
        }
        self.setStory(for: brand)
    }

}
