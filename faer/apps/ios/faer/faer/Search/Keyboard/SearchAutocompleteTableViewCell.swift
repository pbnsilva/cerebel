//
//  SearchAutocompleteTableViewCell.swift
//  faer
//
//  Created by pluto on 06.08.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class SearchAutocompleteTableViewCell: UITableViewCell {
    
    static let resuseIdentifier: String = "cellIdentifier"
    
    private let labelTag: Int = 5
    
    var label: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.label = self.viewWithTag(labelTag) as? UILabel
        
        let backView: UIView = UIView(frame: self.frame)
        backView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        self.selectedBackgroundView = backView // custom selected color
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
