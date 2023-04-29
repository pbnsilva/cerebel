//
//  ProductDetailInfoCollectionViewCell.swift
//  faer
//
//  Created by venus on 12.12.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import CoreLocation

class ProductDetailInfoCollectionViewCell: ProductDetailCollectionViewCell {
    
    @IBOutlet weak var aboutText: UITextView!
    @IBOutlet weak var aboutTitle: UILabel!
    @IBOutlet weak var aboutPrice: UILabel!
    @IBOutlet weak var aboutBrand: UIButton!
    @IBOutlet weak var findStoreBtn: UIButton!
    @IBAction func findStoreBtnTapped(_ sender: Any) {
        
        self.delegate?.mapTapped()
        
    }
    @IBOutlet weak var topMargin: NSLayoutConstraint!
    @IBAction func brandDetailsBtn(_ sender: Any) {
        self.delegate?.brandTapped()
    }
    @IBAction func brandNameTapped(_ sender: Any) {
        self.delegate?.brandTapped()
    }
    
    private var item: Item?
    
    static let reuseId = "productDetailsCellInfoReuseIdentifier"
    static let nibName = "ProductDetailInfoCollectionViewCell"
    
    private let defaultFabric: String = "Visit store for more details."
        
    private weak var originalPrice: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.originalPrice = self.viewWithTag(1) as? UILabel
        // remove left margin from textviews
        
        self.aboutText.textContainerInset = UIEdgeInsets.zero
        self.aboutText.textContainer.lineFragmentPadding = 0
        self.aboutText.textContainer.lineBreakMode = .byTruncatingTail
        
        
        // add tap to brand label
    }
    
    @objc
    private func handleTap(sender: UITapGestureRecognizer) {
        self.delegate?.storeTapped()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.item = nil
    }
    
    //MARK: Custom Functions
    
    private func priceFormatted(price: Double) -> String {
        return price.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", price) : String(format: "%.2f", price)
    }
    
    public func setItem(_ item: Item) {
        
        self.item = item
        
        // header
        self.aboutTitle.text = item.name
        self.aboutBrand.setTitle("by \(item.brand)", for: .normal)
        
        let currencySymbol: String = item.preferredPrice()?.currencySymbol ?? ""
        
        self.aboutPrice?.text = "\(currencySymbol) \(self.priceFormatted(price: item.preferredPrice()?.value ?? 0))"
        
        if let originalPriceValue = item.preferredPrice()?.originalValue {
            let originalPrice: String = "\(currencySymbol) \(self.priceFormatted(price: originalPriceValue))"
            let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: originalPrice)
            attributeString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.thick.rawValue, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(.foregroundColor, value: UIColor.lightGray.withAlphaComponent(0.8), range: NSMakeRange(0, attributeString.length))

            self.originalPrice?.attributedText = attributeString
        }

        // description
        self.aboutText.font = UIFont(name: StyleGuide.fontBody, size: self.aboutText.font!.pointSize) // IB bug: Manuall set font, as open Sans is not recognized properly when using attributedText
        self.aboutText.text = item.about?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        self.layoutSubviews()
        self.setNeedsDisplay()

        // very dirty hack to adjust for iphonex notch
        guard let _ = self.globalPoint, self.globalPoint!.y == 0, let _ = UIApplication.shared.keyWindow else { return } // only handle if we are on the top of the screen || first cell
        
        if #available(iOS 11, *) {
            self.topMargin.constant = max(UIApplication.shared.keyWindow!.safeAreaInsets.top + 10, self.topMargin.constant) // ensure we have at least inital height
        }

    }
    
}
