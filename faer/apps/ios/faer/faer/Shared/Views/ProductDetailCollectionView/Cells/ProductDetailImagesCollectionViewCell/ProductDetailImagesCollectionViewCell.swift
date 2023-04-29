//
//  ProductDetailImagesCollectionViewCell.swift
//  faer
//
//  Created by venus on 05.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class ProductDetailImagesCollectionViewCell: UICollectionViewCell {
    
    static let nibName: String = "ProductDetailImagesCollectionViewCell"
    
    static let reuseIdentifer: String = "ProductDetailImagesCollectionViewCell"
    
    private weak var collectionView: UICollectionView?
    
    private var imageURLs: [URL]?
    
    private var imageCounter: UILabel?
    
    private var imageCounterContainer: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.collectionView = self.viewWithTag(1) as? UICollectionView
        
        self.collectionView?.dataSource = self
        
        self.collectionView?.delegate = self
        
        self.imageCounter = self.viewWithTag(2) as? UILabel
        
        self.imageCounterContainer = self.viewWithTag(3)
        
        self.collectionView?.register(UINib(nibName: ProductDetailImagesImageCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: ProductDetailImagesImageCollectionViewCell.reuseIdentifer)
        
    }
    
    func configure(imageURLs: [URL]) {
        
        if let flow = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            
            let insets: CGFloat = max(self.collectionView!.contentInset.bottom + self.collectionView!.contentInset.top + flow.sectionInset.bottom + flow.sectionInset.top, 3)
            
            flow.itemSize = CGSize(
                width: self.bounds.width,
                height: self.bounds.height - insets)
        } // if we do this in awakeNIB the right size is not available yet
        
        self.imageURLs = imageURLs
        
        // set image count info
        if imageURLs.count > 1 {
            self.imageCounter?.text = "1 / \(self.imageURLs!.count)"
            self.imageCounterContainer?.isHidden = false
        } else {
            self.imageCounterContainer?.isHidden = true
        }
        
        self.collectionView?.reloadData()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageCounterContainer?.isHidden = true
        self.imageCounter?.text = nil
        self.imageCounterContainer?.alpha = 1
    }
    
    
}

extension ProductDetailImagesCollectionViewCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageURLs?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueCell(ProductDetailImagesImageCollectionViewCell.reuseIdentifer, indexPath: indexPath) as! ProductDetailImagesImageCollectionViewCell
        
        cell.configure(imageURL: self.imageURLs![indexPath.row])
        
        return cell
    }
    
}

extension ProductDetailImagesCollectionViewCell: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        
    }
}

extension ProductDetailImagesCollectionViewCell: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.2) {
            self.imageCounterContainer?.alpha = 0
        }
    }
    
}

