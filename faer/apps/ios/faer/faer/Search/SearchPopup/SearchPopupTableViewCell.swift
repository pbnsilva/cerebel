//
//  SearchPopupTableViewCell.swift
//  faer
//
//  Created by pluto on 26.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class SearchPopupTableViewCell: UITableViewCell {
    
    static let resuseIdentifier: String = "SearchPopupTableViewCell"

    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
