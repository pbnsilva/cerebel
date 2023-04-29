//
//  ProductDetailImagesImageCollectionViewCell.swift
//  faer
//
//  Created by venus on 05.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import SDWebImage
import UIImageColors

class ProductDetailImagesImageCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifer: String = "ProductDetailImagesImageCollectionViewCell"
    
    static let nibName: String = "ProductDetailImagesImageCollectionViewCell"
    
    private weak var imageView: UIImageView?
    
    private weak var scrollView: UIScrollView?
    
    override func awakeFromNib() {
        
        self.scrollView = self.viewWithTag(2) as? UIScrollView
        
        self.imageView = self.viewWithTag(3) as? UIImageView
        
        self.scrollView!.delegate = self
        
        scrollView?.minimumZoomScale = 1.0
        scrollView?.maximumZoomScale = 6.0
        
    }
    
    func configure(imageURL: URL) {
        
        self.imageView?.sd_setImage(with: imageURL, completed: nil)
        /*
        // try to back fill color
        self.backgroundColor = .green
        self.imageView?.backgroundColor = .yellow
        
        self.imageView?.sd_setImage(with: imageURL, completed: { [weak self] (image, error, cacheType, url) in
            guard let _ = image, error == nil else {
                return
            }
            
            image!.getColors { [weak self] colors in
                self?.backgroundColor = .black // colors.background
                /*backgroundView.backgroundColor = colors.background
                 mainLabel.textColor = colors.primary
                 secondaryLabel.textColor = colors.secondary
                 detailLabel.textColor = colors.detail*/
            }
            
        })
*/
                
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.image = nil
    }
}

extension ProductDetailImagesImageCollectionViewCell: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        UIView.animate(withDuration: 0.2, animations: {
           scrollView.zoomScale = 1
        })
    }
    
    
}
