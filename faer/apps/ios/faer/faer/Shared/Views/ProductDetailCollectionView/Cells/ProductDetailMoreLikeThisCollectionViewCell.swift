//
//  ProductDetailMoreLikeThisCollectionViewCell.swift
//  faer
//
//  Created by pluto on 05.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import SDWebImage

class ProductDetailMoreLikeThisCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier: String = "ProductDetailMoreLikeThisCollectionViewCell"
    
    static let nibName: String = ProductDetailMoreLikeThisCollectionViewCell.reuseIdentifier
    
    private weak var imageView: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView = self.viewWithTag(1) as? UIImageView
    }
    
    func configure(item: Item) {
        
        guard let url = item.imageURLs.first else { return }
        
        self.imageView?.sd_setImage(with: url, completed: nil)
        
//        self.imageView?.imageFromServerURL(url, placeHolder: nil)
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView?.image = nil
    }
    
}

let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    
    func imageFromServerURL(_ url: URL, placeHolder: UIImage?) {
        
        self.image = nil
        if let cachedImage = imageCache.object(forKey: NSString(string: url.absoluteString)) {
            self.image = cachedImage
            return
        }
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            
            //print("RESPONSE FROM API: \(response)")
            if error != nil {
                print("ERROR LOADING IMAGES FROM URL: \(error)")
                DispatchQueue.main.async {
                    self.image = placeHolder
                }
                return
            }
            DispatchQueue.main.async {
                if let data = data {
                    if let downloadedImage = UIImage(data: data) {
                        imageCache.setObject(downloadedImage, forKey: NSString(string: url.absoluteString))
                        self.image = downloadedImage
                    }
                }
            }
        }).resume()
    }
}
