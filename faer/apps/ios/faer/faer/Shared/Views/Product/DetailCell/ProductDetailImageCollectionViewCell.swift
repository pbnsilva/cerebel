//
//  ProductDetailImageCollectionViewCell.swift
//  faer
//
//  Created by venus on 12.12.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import Hero
import SDWebImage

class ProductDetailImageCollectionViewCell: ProductDetailCollectionViewCell, UIScrollViewDelegate {
    
    static let reuseId: String = "productDetailsCellImageReuseIdentifier"
    static let nibName: String = "ProductDetailImageCollectionViewCell"

    weak var imageView: UIImageView?
    weak var scrollView: UIScrollView?
    
    private var tap: UITapGestureRecognizer?
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        //setup tap handler since the scrollView consumes all gestures
        //https://stackoverflow.com/questions/27193136/how-to-send-the-touch-events-of-uiscrollview-to-the-view-behind-it
        self.tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap!.numberOfTapsRequired = 2
        tap!.cancelsTouchesInView = false
        self.addGestureRecognizer(tap!)
        
        self.imageView = self.viewWithTag(1) as? UIImageView
        self.scrollView = self.viewWithTag(2) as? UIScrollView
        self.scrollView?.delegate = self
        
    }
    
    @objc
    private func handleTap(sender: UITapGestureRecognizer) {
        self.delegate?.storeTapped()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.sd_cancelCurrentImageLoad()
        imageView?.sd_setImage(with: nil, completed: nil)
        imageView?.image = nil
        self.imageView?.hero.id = nil
    }
    
    func setImage(url: URL, _ heroId: String?) {
        self.hero.id = heroId
        self.imageView?.sd_imageIndicator = SDWebImageActivityIndicator.gray
        self.imageView?.sd_setImage(with: url, placeholderImage: nil)
    }
        
    //MARK: UIScrollViewDelegate

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
