//
//  RichSectionLoadingCollectionViewCell.swift
//  faer
//
//  Created by pluto on 01.11.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class RichSectionLoadingCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier: String = "RichSectionLoadingCollectionViewCell"

    static let nibName: String = "RichSectionLoadingCollectionViewCell"

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.activityIndicator.startAnimating()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.activityIndicator.startAnimating()
    }

}
