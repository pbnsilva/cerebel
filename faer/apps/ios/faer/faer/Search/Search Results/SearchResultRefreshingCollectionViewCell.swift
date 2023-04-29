//
//  SearchResultRefreshingCollectionViewCell.swift
//  faer
//
//  Created by pluto on 31.08.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class SearchResultRefreshingCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifer: String = "SearchResultRefreshingCollectionViewCell"
    static let nibName: String = "SearchResultRefreshingCollectionViewCell"
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
