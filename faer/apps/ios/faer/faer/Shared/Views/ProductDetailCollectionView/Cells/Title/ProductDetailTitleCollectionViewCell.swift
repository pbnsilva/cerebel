//
//  ProductDetailTitleCollectionViewCell.swift
//  faer
//
//  Created by pluto on 05.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class ProductDetailTitleCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifer: String = "ProductDetailTitleCollectionViewCell"
    
    static let nibName: String = "ProductDetailTitleCollectionViewCell"
    
    private weak var title: CopyableLabel?
    
    private weak var price: CopyableLabel?
    
    private weak var originalPrice: CopyableLabel?

    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.title = self.viewWithTag(1) as? CopyableLabel
        self.price = self.viewWithTag(2) as? CopyableLabel
        self.originalPrice = self.viewWithTag(3) as? CopyableLabel

    }
    
    private func priceFormatted(price: Double) -> String {
        return price.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", price) : String(format: "%.2f", price)
    }

    
    func configure(item: Item) {
        
        self.title?.text = item.name
        
        var currencySymbol: String = "\(item.preferredPrice()?.currencySymbol ?? "")  "
        
        let price: String
        if item.preferredPrice()?.value == nil || item.preferredPrice()?.value == Price.missingValue {
            price = "Price unavailable"
            currencySymbol = ""
        } else {
            price = "\(self.priceFormatted(price: item.preferredPrice()?.value ?? 0))"
        }
        
        self.price?.text = "\(currencySymbol) \(price)"
        
        if let originalPriceValue = item.preferredPrice()?.originalValue {
            let originalPrice: String = "\(currencySymbol)\(self.priceFormatted(price: originalPriceValue))"
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: originalPrice)
            attributeString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.thick.rawValue, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(.foregroundColor, value: UIColor.lightGray.withAlphaComponent(0.8), range: NSMakeRange(0, attributeString.length))
            
            self.originalPrice?.attributedText = attributeString
        }

        
    }


}
