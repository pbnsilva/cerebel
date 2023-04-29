//
//  DiscoverCollectionReusableView.swift
//  faer
//
//  Created by venus on 19.07.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class BrandProfileCollectionHeaderView: UICollectionReusableView {
    
    static let reuseIdentifer: String = "BrandProfileCollectionHeaderView"

    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var detailDisclosureBtn: UIButton!
    
    @IBAction func detailDisclosureBtnTapped(_ sender: Any) {
        
        
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    func configure(title: String) {
        
        self.title.text = title
        
    }
    
}
