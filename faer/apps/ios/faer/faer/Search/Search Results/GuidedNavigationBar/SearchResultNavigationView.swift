//
//  SearchResultNavigationView.swift
//  faer
//
//  Created by pluto on 06.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

protocol SearchResultNavigationViewDelegate :class {
    func filterTapped()
    func suggestionsTapped(suggestion: String)
    func saleFilter(_ state: Bool)
}

class SearchResultNavigationView: UIView {
    
   static let height: CGFloat = 90 // must match height in xib
    
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
   weak var delegate: SearchResultNavigationViewDelegate?
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBOutlet weak var filterBtn: UIButton!
    
    @IBAction func filterBtnTapped(_ sender: Any) {
        self.delegate?.filterTapped()
    }
    
    private lazy var guidedSearchTags: [String] = []
    
    private weak var collectionViewContainer: UIView?
    
    private weak var collectionView: UICollectionView?
    
    @IBAction func saleBtnTapped(_ sender: Any) {
        self.salesIcon.isHidden = !self.salesIcon.isHidden
        self.delegate?.saleFilter(!self.salesIcon.isHidden)
    }
    
    @IBOutlet weak var salesIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.filterBtn.isExclusiveTouch = true
        
        self.collectionView = self.viewWithTag(3) as? UICollectionView
        
        self.collectionViewContainer = self.viewWithTag(4)
        
        self.collectionView?.register(UINib(nibName: NavigationViewTagCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: NavigationViewTagCollectionViewCell.reuseIdentifier)
        
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        
        self.collectionView?.reloadData()
        
        self.collectionViewContainer?.isHidden = true
        
    }
    
    func configure(tags: [String], settings: ItemListSettings?) {

        self.guidedSearchTags = tags
        
        self.collectionViewContainer?.isHidden = self.guidedSearchTags.isEmpty
        self.collectionView?.reloadData()
        
        if tags.isEmpty {
            collectionViewHeight.constant = 0
            self.layoutSubviews()
        }
        
        self.salesIcon.isHidden = !(settings?.onSale ?? false)

    }

}

extension SearchResultNavigationView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.suggestionsTapped(suggestion: self.guidedSearchTags[indexPath.row])
    }
    
    
}

extension SearchResultNavigationView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // use dummy cell to let autolayout calculate size / more reliable then flowlayout
        let cell: NavigationViewTagCollectionViewCell = (Bundle.main.loadNibNamed(NavigationViewTagCollectionViewCell.nibName, owner: self, options: nil)![0] as? NavigationViewTagCollectionViewCell)!
        cell.set(title: self.guidedSearchTags[indexPath.row])
        
        let targetSize: CGSize = CGSize(width: 100, height: self.collectionView!.bounds.height - 6)
        let size = cell.contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .defaultLow, verticalFittingPriority: .required)
        return size
    }
    
    
}

extension SearchResultNavigationView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.guidedSearchTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: NavigationViewTagCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: NavigationViewTagCollectionViewCell.reuseIdentifier, for: indexPath) as! NavigationViewTagCollectionViewCell
        cell.set(title: self.guidedSearchTags[indexPath.row])
        return cell
        
    }
    
}

