//
//  SettingsCollectionViewCell.swift
//  faer
//
//  Created by pluto on 05.11.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

protocol SettingsCollectionViewCellDelegate :class {
    func settingsTapped()
}

class SettingsCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier: String = "SettingsCollectionViewCell"
    
    static let nibName: String = "SettingsCollectionViewCell"
    
    weak var delegate: SettingsCollectionViewCellDelegate?

    @IBAction func settingsBtnTapped(_ sender: Any) {
        
        self.delegate?.settingsTapped()
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
