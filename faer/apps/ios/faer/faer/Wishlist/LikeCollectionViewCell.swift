//
//  LikeCollectionViewCell.swift
//  faer
//
//  Created by pluto on 28.09.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import Hero

let likeCollectionViewCellReuseIdentifier = "likeCellIdentifier"

class LikeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
      // self.image.image = nil
    }
    
}
