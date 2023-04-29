//
//  PriceInfoTableViewCell.swift
//  faer
//
//  Created by pluto on 14.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class PriceInfoTableViewCell: UITableViewCell {
    
    static let highestPriceReuseIdentifier: String = "priceHighestInfo"
    static let lowestPriceReuseIdentifier: String = "priceLowestInfo"
        
    private let activeValueTag: Int = 5
    
    var priceInfo: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.priceInfo = self.viewWithTag(self.activeValueTag) as? UILabel
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
