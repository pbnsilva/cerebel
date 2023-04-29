//
//  MapTeaserCollectionViewCell.swift
//  faer
//
//  Created by pluto on 01.11.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import MapKit

protocol MapTeaserCollectionViewCellDelegate :class {
    func hideMapTapped(cell: MapTeaserCollectionViewCell)
}

class MapTeaserCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func hideMapTapped(_ sender: Any) {
        self.delegate?.hideMapTapped(cell: self)
    }
    
    static let reuseIdentifier: String = "MapTeaserCollectionViewCell"
    
    static let nibName: String = "MapTeaserCollectionViewCell"
    
    private let titleNeedle: String = "<stores>"
    
    private let defaultTitle: String = "Discover <stores> shops near you"
    
    weak var delegate: MapTeaserCollectionViewCellDelegate?
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureNoPermissions() {
        self.title.text = "Tap to find shops near you"
    }
    
    func configure(stores: [Store]?) {

        if let stores = stores, !stores.isEmpty {
            self.title.text = defaultTitle.replacingOccurrences(of: self.titleNeedle, with: String(stores.count))
        } else {
            self.title.text = "There are currently no shops around you."
        }        
    }
    
    override func prepareForReuse() {
        self.title.text = nil
        self.imageView.image = nil
    }
    
}
