//
//  BrandItemCollectionViewCell.swift
//  faer
//
//  Created by pluto on 01.11.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import UIImageColors

protocol BrandItemCollectionViewCellDelegate :class {
    func shareBtnTapped(sender: BrandItemCollectionViewCell)
}

class BrandItemCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier: String = "BrandItemCollectionViewCell"
    
    static let nibName: String = "BrandItemCollectionViewCell"

    @IBOutlet weak var likeBtn: ProductActionButton!
    
    @IBAction func likeBtnTapped(_ sender: Any) {
        
        self.likeBtn.isSelected = !self.likeBtn.isSelected

        self.item?.isLiked = self.likeBtn.isSelected
        
    }
    
    @IBOutlet weak var shareBtn: ProductActionButton!
    
    @IBAction func shareBtnTapped(_ sender: Any) {
        
        self.delegate?.shareBtnTapped(sender: self)
        
    }
    
    private var imageView: UIImageView?
    
    private var productInfo: UILabel?
    
    private var price1: UILabel?
    
    private var price2: UILabel?
    
    private var item: Item?
    
    weak var delegate: BrandItemCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.imageView = self.viewWithTag(1) as? UIImageView
        self.productInfo = self.viewWithTag(2) as? UILabel
        self.price1 = self.viewWithTag(3) as? UILabel
        self.price2 = self.viewWithTag(4) as? UILabel

    }
    
    private func priceFormatted(price: Double) -> String {
        return price.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", price) : String(format: "%.2f", price)
    }
    
    func configure(item: Item) {
        
        self.item = item
        
        self.likeBtn.isSelected = item.isLiked
        
        self.productInfo?.text = "\(item.name)"
        
        // configure image
        
   /*     self.imageView?.sd_setImage(with: item.imageURLs.first, completed: { [weak self] (image, error, cacheType, url) in
            guard let _ = image, error == nil else {
                return
            }
            
            self?.imageView?.image?.getColors { [weak self] colors in
                self?.imageView?.backgroundColor = colors.background
                /*backgroundView.backgroundColor = colors.background
                mainLabel.textColor = colors.primary
                secondaryLabel.textColor = colors.secondary
                detailLabel.textColor = colors.detail*/
            }
            
        })*/
        
        self.imageView?.sd_setImage(with: item.imageURLs.first, completed: nil)
        
        // configure original price
        
        var currencySymbol: String = "\(item.preferredPrice()?.currencySymbol ?? "")  "
        
        if let originalPriceValue = item.preferredPrice()?.originalValue {
            let originalPrice: String = "\(currencySymbol)\(self.priceFormatted(price: originalPriceValue))"
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: originalPrice)
            attributeString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.thick.rawValue, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(.foregroundColor, value: UIColor.lightGray.withAlphaComponent(0.8), range: NSMakeRange(0, attributeString.length))
            
            self.price2?.attributedText = attributeString
        }
        
        // configure price
        
        let price: String
        if item.preferredPrice()?.value == nil || item.preferredPrice()?.value == Price.missingValue {
            price = "Price unavailable"
            currencySymbol = ""
        } else {
            price = "\(self.priceFormatted(price: item.preferredPrice()?.value ?? 0))"
        }
        
        if let _ = item.preferredPrice()?.originalValue {
            self.price1?.text = "\(currencySymbol) \(price)"
        } else {
            self.price2?.text = "\(currencySymbol) \(price)"
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.productInfo?.text = nil
        self.price1?.text = nil
        self.imageView?.sd_cancelCurrentImageLoad()
        self.imageView?.image = nil
        self.item = nil
    }

}
