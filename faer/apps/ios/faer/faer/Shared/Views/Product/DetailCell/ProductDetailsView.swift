//
//  ProductDetailsView.swift
//  faer
//
//  Created by venus on 12.12.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import SDWebImage
import CoreLocation

protocol ProductDetailsViewDelegate :class {
    func likeTapped(_ sender: ProductDetailsView)
    func shareTapped(_ sender: ProductDetailsView)
    func storeTapped(_ sender: ProductDetailsView)
    func mapTapped(_ sender: ProductDetailsView)
    func brandTapped(_ sender: ProductDetailsView)
}

class ProductDetailsView: UICollectionViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    static let reuseId = "productDetailsViewReuseIdentifier"
    static let nibName = "ProductDetailsView"
    
    private weak var collectionView: UICollectionView?
    
    @IBOutlet weak var likeBtn: ProductActionButton!
    @IBAction func likeBtnTapped(_ sender: Any) {
        
        self.likeBtn.isSelected = !self.likeBtn.isSelected
        
        if self.shopBtn.isSolid {
            self.likeBtn.isSolid = !self.likeBtn.isSelected
        }
        
        self.delegate?.likeTapped(self)
    }
    
    @IBOutlet weak var shopBtn: ProductActionButton!
    @IBAction func shopBtnTapped(_ sender: Any) {
        self.delegate?.storeTapped(self)
    }
    
    @IBOutlet weak var shareBtn: ProductActionButton!
    
    @IBAction func shareBtnTapped(_ sender: Any) {
        self.delegate?.shareTapped(self)
    }
    
    @IBOutlet weak var mapBtn: ProductActionButton!
    @IBAction func mapBtnTapped(_ sender: Any) {
        self.delegate?.mapTapped(self)
    }
    
    @IBOutlet weak var activityToolbar: UIToolbar!

    public var productCellHeight: CGFloat?

    private var elements: [Any]?
    
    private var storeInfo: String?

  //  private var item: Item?
    
    private var dynamicHeroID: String?
    
    weak var delegate: ProductDetailsViewDelegate?
    
    private weak var title: OutlinedLabel?

    private weak var price: OutlinedLabel?

    private weak var originalPrice: OutlinedLabel?
    
    private var imageURLs: [URL]?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
        self.title = self.viewWithTag(5) as? OutlinedLabel
        self.price = self.viewWithTag(6) as? OutlinedLabel
        self.originalPrice = self.viewWithTag(7) as? OutlinedLabel

        // setup custom cells
        
        self.registerCollectionView()

    }
    
    @objc
    private func handleDoubleTap(sender: UITapGestureRecognizer) {
        self.delegate?.storeTapped(self)
    }
    
    private func registerCollectionView() {
        self.collectionView = self.viewWithTag(9) as? UICollectionView
        // Set the ProductDetailsLayout delegate
        self.collectionView?.dataSource = self
        self.collectionView?.delegate = self
        collectionView?.prefetchDataSource = self
        
        // images
        self.collectionView?.register(UINib(nibName: ProductDetailImageCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: ProductDetailImageCollectionViewCell.reuseId)
        
        // info
        self.collectionView?.register(UINib(nibName: ProductDetailInfoCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: ProductDetailInfoCollectionViewCell.reuseId)

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.elements?.removeAll()
        self.collectionView?.reloadData() // clear the collectionview to avoid image ghosting in parent cv
        self.mapBtn.isHidden = true
        self.title?.text = nil
        self.title?.isHidden = false
        self.price?.isHidden = false
        self.price?.text = nil
        self.originalPrice?.isHidden = false
        self.originalPrice?.attributedText = nil
        self.originalPrice?.text = nil
        self.shareBtn.isSelected = false
        self.shopBtn.isSelected = false
        self.mapBtn.isSelected = false

    }
    
    // MARK: Custom Functions

    private func priceFormatted(price: Double) -> String {
        return price.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", price) : String(format: "%.2f", price)
    }
    
    // to be used for memory warning, clears all visible images
    func handleMemoryWarning() {
        guard let collectionView = self.collectionView else {
            return
        }
        for cell in collectionView.visibleCells {
            if let imageCell = cell as? ProductDetailImageCollectionViewCell {
                imageCell.imageView?.sd_setImage(with: nil, completed: nil)
            }
        }
    }
 
    public func set(_ item: Item, heroID: String? = nil) {
        
        self.dynamicHeroID = heroID
        
        self.elements = Array(item.imageURLs.prefix(5)) // don't show more than 5 images
        
        self.imageURLs = Array(item.imageURLs.prefix(5))
        
        self.title?.setAttributedTitle(title: "\(item.name)\nby \(item.brand)")
        
        let currencySymbol: String = item.preferredPrice()?.currencySymbol ?? ""

        self.price?.setAttributedTitle(title: "\(currencySymbol) \(self.priceFormatted(price: item.preferredPrice()?.value ?? 0))")

        if let originalPriceValue = item.preferredPrice()?.originalValue {
            let originalPrice: String = "\(currencySymbol) \(self.priceFormatted(price: originalPriceValue))"
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: originalPrice)
            attributeString.addAttribute(.baselineOffset, value: 0, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.thick.rawValue, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(.foregroundColor, value: UIColor.white, range: NSMakeRange(0, attributeString.length))

            self.originalPrice?.setAttributedTitle(title: attributeString)
        }
        
        if let _ = item.style {
            self.elements?.insert(item.style!.imageURL, at: 0)
        }
        
        self.elements?.append(item) // add item info page
        
        if let _ = item.stores {
            if item.stores!.count > 1 {
                let numberFormatter: NumberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.spellOut
                let st = numberFormatter.string(from: NSNumber(integerLiteral: item.stores!.count))
                self.storeInfo = "There are \(st!) stores near you"
            } else {
                self.storeInfo = "There is one store near you"
            }
        }
        
        self.likeBtn?.isSelected = User.shared.isLiked(item: item)
        self.collectionView?.contentOffset.x = 30 // shows that there are multiple views to see
        self.collectionView?.layoutIfNeeded()  // otherwise offset is not visible
        self.collectionView?.reloadData() // this needs to happen last
        
        self.enableMapIfNeeded(for: item)
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layoutSubviews()

    }
    
    private func enableMapIfNeeded(for item: Item) {
        if  CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            return
        }
        
        guard !item.storesInProximity().isEmpty else {
            return
        }
        
        self.mapBtn.isHidden = false
    }
    
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.elements?.count ?? 0 // add 1 placeholder for about cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let _ = self.elements, indexPath.row < self.elements!.count else { // this shouldn't happen, found cases where elements would become empty for unknown reason
            let cell: ProductDetailImageCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailImageCollectionViewCell.reuseId, for: indexPath) as! ProductDetailImageCollectionViewCell
                cell.delegate = self
            return cell
        }
        
        let globalPoint: CGPoint? = self.superview?.convert(self.frame.origin, to: nil)        

        switch self.elements![indexPath.row] {
        case is URL: // return image
            guard
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailImageCollectionViewCell.reuseId, for: indexPath) as? ProductDetailImageCollectionViewCell else {
                return UICollectionViewCell()
            }
            cell.setImage(url: self.elements![indexPath.row] as! URL, self.dynamicHeroID)
            cell.delegate = self

            return cell
        case is Item: // last cell
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailInfoCollectionViewCell.reuseId, for: indexPath) as? ProductDetailInfoCollectionViewCell else {
                return UICollectionViewCell()
            }
            cell.globalPoint = globalPoint

            cell.setItem(self.elements![indexPath.row] as! Item)
            cell.delegate = self
            
            return cell

        default:
            return UICollectionViewCell()
        }
    }
    
    //MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.bounds.width - 1, height: self.collectionView?.bounds.height ?? 0)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.width > 0, let _ = self.elements else { return } // make sure we have content in the view
        
        let cellWidth: CGFloat = scrollView.contentSize.width / CGFloat(self.elements!.count)
        let offset: CGFloat = 50
        // we want the product info to disappear on the product info and maps views
        let beforeLastCellOffset:CGFloat = scrollView.contentSize.width - (cellWidth) - offset
        if scrollView.contentOffset.x > beforeLastCellOffset {
            self.title?.isHidden = true
            self.price?.isHidden = true
            self.originalPrice?.isHidden = true
            self.likeBtn.isSolid = self.likeBtn.isSelected ? false : true
            self.shareBtn.isSolid = true
            self.shopBtn.isSolid = true
            self.mapBtn.isSolid = true
        }
        if scrollView.contentOffset.x < beforeLastCellOffset {
            self.title?.isHidden = false
            self.price?.isHidden = false
            self.originalPrice?.isHidden = false
            self.likeBtn.isSolid = false
            self.shareBtn.isSolid = false
            self.shopBtn.isSolid = false
            self.mapBtn.isSolid = false
        }
    }
    
}

// MARK: ProductDetailCollectionViewCellDelegate
extension ProductDetailsView: ProductDetailCollectionViewCellDelegate {
    func mapTapped() {
        self.delegate?.mapTapped(self)
    }
    
    func storeTapped() {
        self.delegate?.storeTapped(self)
    }
    
    func brandTapped() {
        self.delegate?.brandTapped(self)
    }
    
}

// MARK: UICollectionViewDataSourcePrefetching
extension ProductDetailsView: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let _ = self.imageURLs else { return }

        var urls: [URL] = []
        for indexPath in indexPaths {
            if self.imageURLs!.indices.contains(indexPath.row) {
                urls.append(self.imageURLs![indexPath.row])
            }
        }
        SDWebImagePrefetcher.shared.prefetchURLs(urls)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {

    }
}

extension ProductDetailsView : ProductDetailsLayoutDelegate {
    
    func sizeForItems(_ collectionView:UICollectionView) -> CGSize {
        return self.bounds.size
    }
    
    func itemsInCollection(_ collectionView:UICollectionView) -> Int {
        return self.elements?.count ?? 0
    }
    
}
