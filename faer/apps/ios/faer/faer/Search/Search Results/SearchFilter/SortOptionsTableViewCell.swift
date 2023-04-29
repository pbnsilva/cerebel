//
//  SortOptionsTableViewCell.swift
//  faer
//
//  Created by pluto on 14.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class SortOptionsTableViewCell: UITableViewCell {
    
    static let reuseIdentifier: String = "SortOptionsTableViewCellIdentifier"
    
    var sortingOption: ItemListSettings.sortingType!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        self.selectedBackgroundView = bgColorView
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        switch selected {
        case true:
            self.accessoryType = .checkmark
        case false:
            self.accessoryType = .none
        }
    }
    
}
