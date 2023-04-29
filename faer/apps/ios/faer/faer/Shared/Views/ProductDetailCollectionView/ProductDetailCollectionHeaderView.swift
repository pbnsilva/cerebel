//
//  DiscoverCollectionReusableView.swift
//  faer
//
//  Created by venus on 19.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class ProductDetailCollectionHeaderView: UICollectionReusableView {
    
    static let reuseIdentifer: String = "ProductDetailCollectionHeaderView"

    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(title: String) {
        
        self.title.text = title
        
    }
    
}
