//
//  LikeCollectionViewHeader.swift
//  faer
//
//  Created by pluto on 02.10.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit

class LikeCollectionViewHeader: UICollectionReusableView {
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var centerY: NSLayoutConstraint!
    
    static let height: CGFloat = 90
    
    static let reuseIdentifier: String = "LikeCollectionViewHeader"
}
