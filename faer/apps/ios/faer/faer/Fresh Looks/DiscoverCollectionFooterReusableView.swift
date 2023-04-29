//
//  DiscoverCollectionFooterReusableView.swift
//  faer
//
//  Created by pluto on 23.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class DiscoverCollectionFooterReusableView: UICollectionReusableView {
    
    

    @IBOutlet weak var noInternetInfo: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    static let reuseIdentifer: String = "DiscoverCollectionFooterReusableViewIdentifier"
    static let nibName: String = "DiscoverCollectionFooterReusableView"
    static let height: CGFloat = 90

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
