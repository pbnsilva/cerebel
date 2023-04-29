//
//  ProductDetailCollectionViewCell.swift
//  faer
//
//  Created by pluto on 18.04.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

protocol ProductDetailCollectionViewCellDelegate :class {
    func storeTapped()
    func mapTapped()
    func brandTapped()
}

class ProductDetailCollectionViewCell: UICollectionViewCell {
    
    public weak var delegate: ProductDetailCollectionViewCellDelegate?
    
    public var globalPoint: CGPoint?
    
}
