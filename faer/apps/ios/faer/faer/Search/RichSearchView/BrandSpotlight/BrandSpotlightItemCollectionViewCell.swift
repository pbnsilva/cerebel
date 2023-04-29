//
//  BrandSpotlightItemCollectionViewCell.swift
//  faer
//
//  Created by pluto on 31.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

protocol BrandSpotlightItemCollectionViewCellDelegate :class {
    
    func tapped(item: Item)
    func tapped(brand: Item)
    func share(sender: UIView, item: Item)
    
}

class BrandSpotlightItemCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier: String = "BrandSpotlightItemCollectionViewCell"
    
    static let nibName: String = "BrandSpotlightItemCollectionViewCell"
    
    weak var delegate: BrandSpotlightItemCollectionViewCellDelegate?
    
    private var dataSource: [Item]?
    
    private weak var collectionView: UICollectionView?
    
    @IBOutlet weak var title: UILabel!
    
    @IBAction func brandMoreTapped(_ sender: Any) {
        
        if let _ = self.item {
            self.delegate?.tapped(brand: self.item!)
        }
    }
    
    private weak var item: Item?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.configureCollectionView()
    }
    
    private func configureCollectionView() {
        
        self.collectionView = self.viewWithTag(2) as? UICollectionView
        
        self.collectionView?.dataSource = self
        
        self.collectionView?.delegate = self
                
        self.collectionView?.register(UINib(nibName: BrandItemCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: BrandItemCollectionViewCell.reuseIdentifier)

    }
    
    func configure(title: String, items: [Item]) {
        
        self.title.text = title
        
        self.item = items.first
        
        self.dataSource = items
        
        self.collectionView?.reloadData()
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.title?.text = nil
        self.dataSource?.removeAll() // is set nil, collectionview.reload has no effect
        self.collectionView?.reloadData()
    }
    
}

extension BrandSpotlightItemCollectionViewCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueCell(BrandItemCollectionViewCell.reuseIdentifier, indexPath: indexPath) as! BrandItemCollectionViewCell
        
        if let item = self.dataSource?[indexPath.row] {
            cell.configure(item: item)
            cell.tag = indexPath.row
        }
        
        cell.delegate = self
        
        return cell
    }
    
}

extension BrandSpotlightItemCollectionViewCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var size = self.collectionView?.bounds.size
        if let _ = size {
            size!.width = size!.width * 0.7
        }
        
        return size ?? CGSize.zero
    }
    
}


extension BrandSpotlightItemCollectionViewCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let _ = self.dataSource?[indexPath.row] {
            self.delegate?.tapped(item: self.dataSource![indexPath.row])
        }
        
    }
}

extension BrandSpotlightItemCollectionViewCell: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        
    }
}

extension BrandSpotlightItemCollectionViewCell: BrandItemCollectionViewCellDelegate {
    
    private func itemForCell(tag: Int) -> Item? {
        
        guard let _ = self.dataSource, self.dataSource!.indices.contains(tag), let item = self.dataSource?[tag] else {
            return nil
        }
        
        return item
    }
    
    func shareBtnTapped(sender: BrandItemCollectionViewCell) {
        
        guard let item = itemForCell(tag: sender.tag) else {
            return
        }
        
        self.delegate?.share(sender: sender, item: item)
    }
    
}
