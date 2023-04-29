//
//  ProductDetailCollectionViewController.swift
//  faer
//
//  Created by pluto on 02.09.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import CoreLocation

class ProductDetailCollectionViewController: UICollectionViewController {
    
    static let storyboardName: String = "ProductDetailCollectionView"
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    internal enum Section: Int {
        case attributes = 0
        case brand = 1
        case images = 2
        case size = 3
        case color = 4
        case about = 5
        case moreBySameBrand = 6
        case moreBySameCategory = 7
        case moreWithSameColor = 8
        case category = 9
        case buy = 10
    }

    var item: Item?
    
    private var isLoadingProductRecommendations: Bool = true
    internal let maxNumberOfRecommendations: Int = 20
    
    private let cellPadding: CGFloat = 10
    
    private lazy var locationManager = CLLocationManager()

    private lazy var sections: [Section] = []
    
    private lazy var cellSizeCache: [IndexPath: UICollectionViewCell] = [:]
    
    private lazy var productRecommendationsDataSource: [Section: [Item]] = [:]
    
    private let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var mapViewBtn: UIBarButtonItem!
    
    @IBAction func mapViewBtnTapped(_ sender: Any) {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            let refreshAlert = UIAlertController(title: "Open settings", message: "Enable location for Faer in your settings to find stores.", preferredStyle: UIAlertController.Style.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            
            present(refreshAlert, animated: true, completion: nil)
            
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            
            // Enable location features
            self.performSegue(withIdentifier: CommonSegues.map.rawValue, sender: self.item?.stores)
            break
        }
    }
    
    @IBOutlet weak var shareBtn: UIBarButtonItem!
    
    @IBAction func shareBtnTapped(_ sender: Any) {
        
        guard let shareUrl = self.item?.shareUrl else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareUrl],
            applicationActivities: nil)
        // required to prevent crash on ipad
        activityViewController.popoverPresentationController?.barButtonItem = self.shareBtn
        
        activityViewController.completionWithItemsHandler = { [weak self] (activityType, completed, returnedItems, activityError) in
            guard completed, let item = self?.item else { return }
            let itemParameters: [String: Any] = Log.serialize(item)
            Log.Tap.share(view: .ProductDetail, parameters: itemParameters)
        }
        
        self.present(activityViewController, animated: true, completion: nil)
    }

    
    @IBOutlet weak var likeBtn: ActionBarButtonItem!

    @IBAction func likeBtnTapped(_ sender: Any) {
        
        self.likeBtn.isSelected = !self.likeBtn.isSelected
        
        self.item?.isLiked = self.likeBtn.isSelected

    }
    
    @IBOutlet weak var buyBtn: UIBarButtonItem!
    
    @IBAction func buyBtnTapped(_ sender: Any) {
        self.performSegue(withIdentifier: CommonSegues.webView.rawValue, sender: self.item)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.registerCells()
        
        // handler for refresh control
        refreshControl.addTarget(self, action: #selector(updateItem), for: .valueChanged)
        self.collectionView.refreshControl = refreshControl

        // Observers to handle AppNotifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentProduct, object: nil) // handle event alerts
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentSearchResult, object: nil) // handle event alerts
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    @objc
    private func handle(notification: NSNotification) {
        guard self.isVisible() else { return }
        
        guard let userInfo = AppNotifications.UserInfo(notification.userInfo) else { return }
        
        self.performSegue(withIdentifier: userInfo.segue.rawValue, sender: userInfo.payload)
    }

    
    private func registerCells() {
        self.collectionView?.register(UINib(nibName: ProductDetailTitlePromotionCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: ProductDetailTitlePromotionCollectionViewCell.reuseIdentifer)
        self.collectionView?.register(UINib(nibName: ProductDetailTitleCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: ProductDetailTitleCollectionViewCell.reuseIdentifer)
        self.collectionView?.register(UINib(nibName: ProductDetailImagesCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: ProductDetailImagesCollectionViewCell.reuseIdentifer)
        self.collectionView?.register(UINib(nibName: ProductDetailAccessoryCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: ProductDetailAccessoryCollectionViewCell.reuseIdentifer)
        self.collectionView?.register(UINib(nibName: ProductDetailBuyCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: ProductDetailBuyCollectionViewCell.reuseIdentifer)
        self.collectionView?.register(UINib(nibName: ProductDetailAboutCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: ProductDetailAboutCollectionViewCell.reuseIdentifer)
        self.collectionView?.register(UINib(nibName: ProductDetailMoreLikeThisCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: ProductDetailMoreLikeThisCollectionViewCell.reuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        CommonSeguesManager.prepare(for: segue, sender: sender)

    }
    
    // MARK: - Custom Implmentation
    
    @objc
    private func updateItem() {
        self.item?.update(completion: { [weak self] (success, error) in
            
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()

                guard success else { return }
                
                self?.collectionView?.reloadSections([Section.attributes.rawValue]) // update only price for now
            //    self?.collectionView?.reloadData()
            }
        })
    }

    func configure(item: Item) {
        
        self.item = item
        
        self.sections = [.attributes, .brand, .images, .about, .buy]
        
        if let _ = self.item?.annotations?.category?.first {
            self.sections.insert(.category, at: 2)
        }
        
        self.likeBtn.isSelected = item.isLiked

        if !item.storesInProximity().isEmpty {
            self.mapViewBtn.tintColor = .black
            self.mapViewBtn.isEnabled = true
        } else {
            self.mapViewBtn.tintColor = .clear
            self.mapViewBtn.isEnabled = false
        }
        
        self.collectionView?.reloadData()
        
        self.updateItem()
        
        self.loadProductRecommendations()
        
        Log.View.productDetail(self.item!)

    }
    
    internal func configureProductRecommendations(recos: [Section: [Item]]) {

        let sortedSections = Array(recos.keys).sorted(by: { $0.rawValue < $1.rawValue })

        self.collectionView?.performBatchUpdates({
            for section in sortedSections {
                // ensure even number of items for the 2 column layout

                var maxEntry: Int = recos[section]!.count > self.maxNumberOfRecommendations ? self.maxNumberOfRecommendations : recos[section]!.count
                if recos[section]!.count % 2 != 0 {
                    maxEntry = max(1, recos[section]!.count - 1)
                }
                // update data source
                self.productRecommendationsDataSource[section] = Array(recos[section]!.prefix(upTo: maxEntry))
                self.sections.append(section)
                self.collectionView?.insertSections([self.sections.count-1])
            }
        }, completion: nil)

        self.isLoadingProductRecommendations = false

     }

    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let currentSection: Section = self.sections[section]
        switch currentSection {
        case .moreBySameBrand, .moreBySameCategory, .moreWithSameColor:
            if let _ = productRecommendationsDataSource[currentSection], productRecommendationsDataSource[currentSection]!.count > 0 {
                return productRecommendationsDataSource[currentSection]!.count
            }
            return 0
        default:
            return 1
        }
    }
    
    // used to calculate cell size with auto layout
    private func getDummyCell(collectionView: UICollectionView, for indexPath: IndexPath) -> UICollectionViewCell {
        
        guard self.cellSizeCache[indexPath] == nil else {
            return self.cellSizeCache[indexPath]!
        }
        
        switch self.sections[indexPath.section] {
        case Section.attributes:
            if let _ = item!.promotion {
                let cell: ProductDetailTitlePromotionCollectionViewCell = (Bundle.main.loadNibNamed(ProductDetailTitlePromotionCollectionViewCell.nibName, owner: self, options: nil)![0] as? ProductDetailTitlePromotionCollectionViewCell)!
                cell.configure(item: self.item!)
                self.cellSizeCache[indexPath] = cell
                return cell
            } else {
                let cell: ProductDetailTitleCollectionViewCell = (Bundle.main.loadNibNamed(ProductDetailTitleCollectionViewCell.nibName, owner: self, options: nil)![0] as? ProductDetailTitleCollectionViewCell)!
                cell.configure(item: self.item!)
                self.cellSizeCache[indexPath] = cell
                return cell
            }
        case Section.about:
            let cell: ProductDetailAboutCollectionViewCell = (Bundle.main.loadNibNamed(ProductDetailAboutCollectionViewCell.nibName, owner: self, options: nil)![0] as? ProductDetailAboutCollectionViewCell)!
            cell.configure(description: self.item!.about ?? String())
            self.cellSizeCache[indexPath] = cell
            return cell
        case Section.buy:
            let cell: ProductDetailBuyCollectionViewCell = (Bundle.main.loadNibNamed(ProductDetailBuyCollectionViewCell.nibName, owner: self, options: nil)![0] as? ProductDetailBuyCollectionViewCell)!
            self.cellSizeCache[indexPath] = cell
            return cell
        case Section.brand:
            let cell: ProductDetailAccessoryCollectionViewCell = (Bundle.main.loadNibNamed(ProductDetailAccessoryCollectionViewCell.nibName, owner: self, options: nil)![0] as? ProductDetailAccessoryCollectionViewCell)!
            cell.configure(title: "Brand", description: self.item!.brand)
            self.cellSizeCache[indexPath] = cell
            return cell
        case Section.category:
            let cell: ProductDetailAccessoryCollectionViewCell = (Bundle.main.loadNibNamed(ProductDetailAccessoryCollectionViewCell.nibName, owner: self, options: nil)![0] as? ProductDetailAccessoryCollectionViewCell)!
            cell.configure(title: "Category", description: self.item?.annotations?.category?.first?.capitalized ?? String())
            self.cellSizeCache[indexPath] = cell
            return cell
        default:
            return UICollectionViewCell() // fatal
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch self.sections[indexPath.section] {
        case Section.attributes:
            if let _ = item!.promotion {
                let cell: ProductDetailTitlePromotionCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailTitlePromotionCollectionViewCell.reuseIdentifer, for: indexPath) as! ProductDetailTitlePromotionCollectionViewCell
                cell.configure(item: self.item!)
                cell.layoutIfNeeded()
                return cell
            } else {
                let cell: ProductDetailTitleCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailTitleCollectionViewCell.reuseIdentifer, for: indexPath) as! ProductDetailTitleCollectionViewCell
                cell.configure(item: self.item!)
                cell.layoutIfNeeded()
                return cell
            }
        case Section.about:
            let cell: ProductDetailAboutCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailAboutCollectionViewCell.reuseIdentifer, for: indexPath) as! ProductDetailAboutCollectionViewCell
            cell.configure(description: self.item!.about ?? String())
            return cell
        case Section.buy:
            let cell: ProductDetailBuyCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailBuyCollectionViewCell.reuseIdentifer, for: indexPath) as! ProductDetailBuyCollectionViewCell
            return cell
        case Section.brand:
            let cell: ProductDetailAccessoryCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailAccessoryCollectionViewCell.reuseIdentifer, for: indexPath) as! ProductDetailAccessoryCollectionViewCell
            cell.configure(title: "Brand", description: self.item!.brand)
            return cell
        case Section.category:
            let cell: ProductDetailAccessoryCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailAccessoryCollectionViewCell.reuseIdentifer, for: indexPath) as! ProductDetailAccessoryCollectionViewCell
            cell.configure(title: "Category", description: self.item?.annotations?.category?.first?.capitalized ?? String())
            cell.hasTopSeperator = true
            return cell
        case Section.moreBySameBrand, Section.moreBySameCategory, Section.moreWithSameColor:
            let cell: ProductDetailMoreLikeThisCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailMoreLikeThisCollectionViewCell.reuseIdentifier, for: indexPath) as! ProductDetailMoreLikeThisCollectionViewCell
            let sectionItems: [Item] = productRecommendationsDataSource[self.sections[indexPath.section]]!
            cell.configure(item: sectionItems[indexPath.item])
            return cell
        case Section.images:
            let cell: ProductDetailImagesCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailImagesCollectionViewCell.reuseIdentifer, for: indexPath) as! ProductDetailImagesCollectionViewCell
            
            var imageURLs: [URL] = self.item!.imageURLs
            // add style as first image if available
            if let _ = item!.style {
                imageURLs.insert(item!.style!.imageURL, at: 0)
            }
            
            cell.configure(imageURLs: imageURLs)
            return cell
        default:
            return UICollectionViewCell() // fatal
        }

    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionFooter {
            let cell = collectionView.dequeueSupplementary(ProductDetailCollectionFooterView.reuseIdentifer, indexPath: indexPath, kind: kind) as! ProductDetailCollectionFooterView
            cell.activityIndicator.isHidden = !self.isLoadingProductRecommendations
            return cell
        }
        
        let header: ProductDetailCollectionHeaderView = collectionView.dequeueSupplementary(ProductDetailCollectionHeaderView.reuseIdentifer, indexPath: indexPath, kind: kind) as! ProductDetailCollectionHeaderView
        
        let title: String
        
        switch self.sections[indexPath.section] {
        case .moreBySameBrand:
            title = "More by \(self.item!.brand)"
        case .moreBySameCategory:
            title = "Other \(self.item!.annotations!.category!.first!.capitalized)"
        case .moreWithSameColor:
            title = "You Might Also Like"
        default:
            title = "Foo" // this shouldn't happen
        }
        
        header.configure(title: title)
        
        return header
        
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let segue: CommonSegues
        
        let sender: Any
        
        switch self.sections[indexPath.section] {
        case Section.buy:
            segue = .webView
            sender = self.item!
        case Section.brand:
            segue = .brandProfile
            sender = self.item!
        case Section.category:
            segue = .searchResult
            sender =  self.item!.annotations!.category!.first!
        case Section.moreBySameBrand, .moreBySameCategory, .moreWithSameColor:
            segue = .PDP
            let sectionItems: [Item] = productRecommendationsDataSource[self.sections[indexPath.section]]!

            sender = sectionItems[indexPath.item]
        default:
            return
        }

        self.performSegue(withIdentifier: segue.rawValue, sender: sender)
        
    }

}

extension ProductDetailCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout, 
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if self.sections[section] == .moreBySameBrand || self.sections[section] == .moreBySameCategory || self.sections[section] == .moreWithSameColor {
            return CGSize(width: collectionView.bounds.width, height: 80)
        }
        
        return CGSize.zero
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        if self.isLoadingProductRecommendations && self.sections[section] == self.sections.last {
            return CGSize(width: collectionView.bounds.width, height: 80)
        }
        
        if !self.isLoadingProductRecommendations && self.sections[section] == self.sections.last {
            
            let height: CGFloat
            if let layout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
                height = layout.minimumInteritemSpacing
            } else {
                height = 10
            }
            
            return CGSize(width: collectionView.bounds.width, height: height)
        }
        
        return CGSize.zero

    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch self.sections[indexPath.section] {
            
        case .moreBySameBrand, .moreBySameCategory, .moreWithSameColor:
            return self.sizeForMoreByCell()
        case .images:
            return CGSize(width: UIScreen.main.bounds.width - cellPadding, height: UIScreen.main.bounds.height * self.scaleForAspectRatio())
        default:
            let cell = self.getDummyCell(collectionView: collectionView, for: indexPath)
            let targetSize: CGSize = CGSize(width: UIScreen.main.bounds.width - cellPadding, height: 50)
            let size = cell.contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
            return size
        }
    }
    
    private func scaleForAspectRatio() -> CGFloat {
        let aspectRatio: CGFloat = UIScreen.main.bounds.height / UIScreen.main.bounds.width
        
        if aspectRatio > 2 {
            return 0.7
        }
        return 0.9
        
        /*
         iphone xr: aspect ration 2.1642512077294684
         iphone x: aspect ration 2.1653333333333333
         ipad: aspect ration 1.3333333333333333
         iphone 5se: aspect ration 1.775
         */
    }
    
    private func sizeForMoreByCell() -> CGSize {

        var spacing: CGFloat = 10
        let columns: CGFloat = 2
        if let layout: UICollectionViewFlowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            spacing = layout.minimumInteritemSpacing
        }
        let side: CGFloat = (UIScreen.main.bounds.width / columns) - (spacing / columns)
        return CGSize(width: side, height: side)
    
    }
    
}
