//
//  PopularCategoryCollectionViewCell.swift
//  faer
//
//  Created by pluto on 31.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class PopularCategoryCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier: String = "PopularCategoryCollectionViewCell"
    
    static let nibName: String = "PopularCategoryCollectionViewCell"

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
