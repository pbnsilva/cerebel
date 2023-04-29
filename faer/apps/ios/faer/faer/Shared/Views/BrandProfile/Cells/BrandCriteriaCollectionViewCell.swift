//
//  BrandCriteriaCollectionViewCell.swift
//  faer
//
//  Created by pluto on 01.02.19.
//  Copyright © 2019 pluto. All rights reserved.
//

import UIKit

class BrandCriteriaCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier: String = "BrandCriteriaCollectionViewCell"
    
    static let nibName: String = BrandCriteriaCollectionViewCell.reuseIdentifier
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
