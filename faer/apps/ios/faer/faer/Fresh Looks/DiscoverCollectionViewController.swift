//
//  DiscoverCollectionViewController.swift
//  test
//
//  Created by pluto on 12.09.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import SquareMosaicLayout
import NotificationBannerSwift
import StoreKit
import Hero
import SDWebImage

class DiscoverCollectionViewController: UIViewController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    static let storyboardName: String = "Discover"
    
    private let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var infoView: UIView!
    
    private let displayedInfoViewKey: String = "discoveryDisplayedInfoViewKey"
    @IBOutlet weak var infoTranslucentView: UIView!
    @IBAction func infoViewSwiped(_ sender: Any) {
        self.hideInfoView()
    }
    
    static let storyboardID: String = "discoverFeedSB"
    
    static let lastRefreshKey: String = "lastRefreshKey"
    private var lastRefresh: Date? {
        didSet {
            UserDefaults.standard.set(self.lastRefresh, forKey: DiscoverCollectionViewController.lastRefreshKey)
        }
    }
    
    // Cell Reuse Identifiers
    private let loadingCellReuseId = "loadingCellReuseId"
    
    //Data Source Management
    
    typealias Section = Int
    private var defaultSectionSize: Int = 50
    private var dataSource: [Style]?
    private var totaldataSourceStyles: Int = 1
    private var dataSourceLoadOperations = [Section: StyleListLoadOperation]()
    private let dataSourceLoadQueue = OperationQueue()

    var failedToLoadFeed: Bool = false
    
    // Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)         // get notified when app moves to foregground
        
        self.configureCollectionView()
        self.updateFeedIfNeeded()
        
        if UserDefaults.standard.bool(forKey: self.displayedInfoViewKey) {
            self.infoView.isHidden = true
        }
        
        // add blur effect to info view
        let effect = UIVisualEffectView(frame: self.infoTranslucentView.frame)
        effect.effect = UIBlurEffect(style: .light)
        effect.alpha = 0.9
        self.infoTranslucentView.addSubview(effect)
        
        // disable mem caching to avoid OoM crashes
        SDImageCache.shared.config.shouldCacheImagesInMemory = false
        
        // Observers to handle AppNotifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentProduct, object: nil) // handle product alerts
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentSearchResult, object: nil) // handle brand alerts
        
        // last refresh
        lastRefresh = UserDefaults.standard.object(forKey: DiscoverCollectionViewController.lastRefreshKey) as? Date
        self.configureDataSource()
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    private func configureCollectionView() {
        //setup collectionview layout
        self.collectionView.register(UINib(nibName: DiscoverCollectionHeaderReusableView.nibName, bundle: nil), forSupplementaryViewOfKind: SquareMosaicLayoutSectionHeader, withReuseIdentifier: DiscoverCollectionHeaderReusableView.reuseIdentifer)
        self.collectionView.register(UINib(nibName: DiscoverCollectionFooterReusableView.nibName, bundle: nil), forSupplementaryViewOfKind: SquareMosaicLayoutSectionFooter, withReuseIdentifier: DiscoverCollectionFooterReusableView.reuseIdentifer)
        self.collectionView.register(UINib(nibName: NoInternetCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: NoInternetCollectionViewCell.reuseIdentifier)
        
        self.collectionView?.collectionViewLayout = SingleCellLayout()
        
        // collectionview delegates
        self.collectionView.delegate = self
        self.collectionView?.prefetchDataSource = self
        
        // handler for refresh control
        refreshControl.addTarget(self, action: #selector(self.configureDataSource), for: .valueChanged)
        self.collectionView.refreshControl = refreshControl
    }
    
    private func updateLayoutIfNeeded() {
        
        let newLayout: SquareMosaicLayout
        
        if !self.failedToLoadFeed {
            newLayout = DiscoverLayout()
            (newLayout as! DiscoverLayout).discoverDelegate = self
        } else {
            newLayout = SingleCellLayout()
            (newLayout as! SingleCellLayout).discoverDelegate = self
        }
        
        guard
            let _ = self.collectionView,
            type(of: self.collectionView!.collectionViewLayout) != type(of: newLayout) // avoid uncessary layout updates
            else { return }
        
        self.collectionView?.setCollectionViewLayout(newLayout, animated: false)
    }

    
    @objc
    private func handle(notification: NSNotification) {
        guard self.isVisible() else { return }
        
        guard let userInfo = AppNotifications.UserInfo(notification.userInfo) else { return }
        
        self.performSegue(withIdentifier: userInfo.segue.rawValue, sender: userInfo.payload)
    }

    
    @objc
    private func appMovedToForeground() {
        self.updateFeedIfNeeded()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.hideInfoView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateFeedIfNeeded()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        CommonSeguesManager.prepare(for: segue, sender: sender)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: Data source handling
    // initializes a new feed list loading the data from remote
    @objc
    private func configureDataSource() {
        
        let section: Int = 0
        self.dataSourceLoadOperations.removeAll()
        self.dataSourceLoadQueue.cancelAllOperations()
        guard dataSourceLoadOperations[section] == nil else { return }
        let dataSourceLoadOperation: StyleListLoadOperation = StyleListLoadOperation(section: section, size: self.defaultSectionSize)
        dataSourceLoadOperation.completionHandler = { [weak self] (list, error) in
            
            self?.endRefreshing()
            
            guard error == nil, list != nil else {
                self?.failedToLoadFeed = true
                self?.dataSourceLoadOperations.removeValue(forKey: section)
                return
            }
            
            self?.failedToLoadFeed = false
            
            guard list!.styles.count > 0 else {
                return
            }
            
            DispatchQueue.main.async {
                self?.totaldataSourceStyles = list!.totalStyles
                self?.dataSource = list!.styles
                self?.updateLayoutIfNeeded()
                self?.collectionView?.reloadData()
                self?.dataSourceLoadOperations.removeValue(forKey: section)
                self?.lastRefresh = Date()
            }
        }
        dataSourceLoadQueue.addOperation(dataSourceLoadOperation)
        dataSourceLoadOperations[section] = dataSourceLoadOperation

    }
    
    private func endRefreshing() {
        
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
        }
    }
    
    private func refreshView() {
        self.updateLayoutIfNeeded()
        self.collectionView?.reloadData()
    }
    
   
    // MARK: Data Handling
    private func updateFeedIfNeeded() {
        
        // update every 300 seconds
        guard let _ = self.lastRefresh, self.lastRefresh!.timeIntervalSinceNow > abs(18000) else { // 5h in seconds
            return
        }
        
        self.configureDataSource()
    }
    
    //info view
    @objc
    private func showInfoView(sender: UITapGestureRecognizer) {
        self.infoView.isHidden = false
    }
    
    private func hideInfoView() {
        self.infoView.isHidden = true
        UserDefaults.standard.set(true, forKey: displayedInfoViewKey)
    }
}

// MARK: UICollectionViewDataSource
extension DiscoverCollectionViewController: UICollectionViewDataSource {
    
    // MARK: Custom data handlers
    
    private func section(at indexPath: IndexPath) -> Int {
        // calculate virtual section for pagination; due to the collectionviewlayout we have only one section
        return (Int((Double(indexPath.row) / Double(self.defaultSectionSize)).rounded(.up)))
    }
    
    private func loadRows(at indexPath: IndexPath) {
        
        guard let _ = dataSource else { return }
        
        let sectionToLoad: Int = (Int((Double(indexPath.row) / Double(self.defaultSectionSize)).rounded(.up)))
        
        let maxSections: Int = (Int((Double(totaldataSourceStyles) / Double(self.defaultSectionSize)).rounded(.up)))
        
        guard
            sectionToLoad <= maxSections,
            dataSourceLoadOperations[sectionToLoad] == nil
        else { return }
        
        guard
            let _ = dataSource,
            self.dataSource!.count <= self.totaldataSourceStyles,
            dataSourceLoadOperations[sectionToLoad] == nil
        else { return }
        let dataLoadOperation = StyleListLoadOperation(section: sectionToLoad, size: self.defaultSectionSize)
        dataLoadOperation.completionHandler = { [weak self] (list, error) in

            if error != nil {
                self?.dataSourceLoadOperations.removeValue(forKey: sectionToLoad)
                return
            }
            
            guard let _ = self, let _ = self?.dataSource, let _ = list, list!.styles.count > 0 else {
                return
            }
            
            DispatchQueue.main.async {
                self?.collectionView?.performBatchUpdates({
                    let startIndex: Int = self!.dataSource!.count
                    let endIndex: Int = startIndex + list!.styles.count
                    self?.dataSource?.append(contentsOf: list!.styles)
                    for index in startIndex..<endIndex {
                        self?.collectionView?.insertItems(at: [IndexPath(row: index, section: 0)])
                    }
                }, completion: nil)
            }
        }
        
        dataSourceLoadQueue.addOperation(dataLoadOperation)
        dataSourceLoadOperations[sectionToLoad] = dataLoadOperation
        
    }
    
    private func configure(_ cell: DiscoverCollectionViewCell, with style: Style) {
        
        // configure cell if data available
        cell.imageView?.sd_imageIndicator = SDWebImageActivityIndicator.gray
        cell.imageView?.sd_setImage(with: style.imageURL, placeholderImage: nil)
        
        if let promotion = style.items?.first?.promotion {
            cell.setPromotion(text: promotion)
        }
        
        if
            let _ = style.items,
            let heroId = style.items?.first?.hashValue
        {
            cell.hero.id = String(heroId)
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard !self.failedToLoadFeed else { return 1 }
        
        return self.dataSource?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // handle no connection or data
        guard let _ = self.dataSource else {
            if !Network.shared.isReachable() {
                return collectionView.dequeueReusableCell(withReuseIdentifier: NoInternetCollectionViewCell.reuseIdentifier, for: indexPath)
            } else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: loadingCellReuseId, for: indexPath)
            }
        }
        
        // default
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiscoverCollectionViewCell.reuseIdentifier, for: indexPath) as! DiscoverCollectionViewCell
        if let style = self.dataSource?[indexPath.row] {
            self.configure(cell, with: style)
        }
        
        return cell
        
    }
        
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case SquareMosaicLayoutSectionHeader:
            let header: UICollectionReusableView = collectionView.dequeueSupplementary(DiscoverCollectionHeaderReusableView.reuseIdentifer, indexPath: indexPath, kind: kind)
            return header
        case SquareMosaicLayoutSectionFooter:
            let footer: DiscoverCollectionFooterReusableView = collectionView.dequeueSupplementary(DiscoverCollectionFooterReusableView.reuseIdentifer, indexPath: indexPath, kind: kind) as! DiscoverCollectionFooterReusableView
            if !Network.shared.isReachable() {
                footer.activityView.isHidden = true
                footer.noInternetInfo.isHidden = false
            } else {
                footer.activityView.isHidden = false
                footer.noInternetInfo.isHidden = true
            }
            return footer
        default:
            fatalError()
        }
    }
    
}

// MARK: UICollectionViewDelegate
extension DiscoverCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard
            let source = self.dataSource,
            source.indices.contains(indexPath.row),
            let item = source[indexPath.row].items?.first
        else { return }
        
        item.style = source[indexPath.row]
        
        self.performSegue(withIdentifier: CommonSegues.PDP.rawValue, sender: item)

        Log.Tap.item(view: .Feed, item: item)
    }
    
}


// MARK: UICollectionViewDataSourcePrefetching
extension DiscoverCollectionViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        
        var urls: [URL] = []
        for indexPath in indexPaths {
            guard let _ = dataSource else { continue }
            if indexPath.row > (indexPath.count / 2) {
                self.loadRows(at: indexPath)
            }
            
            // preload images
            if let url = self.dataSource?[indexPath.row].imageURL {
                 urls.append(url)
            }
        }
        
        SDWebImagePrefetcher.shared.prefetchURLs(urls)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        
    }
}

extension DiscoverCollectionViewController: DiscoverLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, referenceHeightForHeaderInSection section: Int) -> CGFloat {
        return DiscoverCollectionHeaderReusableView.height
    }

    func collectionView(_ collectionView: UICollectionView, referenceHeightForFooterInSection section: Int) -> CGFloat {
        guard let _ = self.dataSource, self.dataSource!.count == self.totaldataSourceStyles else {
            return DiscoverCollectionFooterReusableView.height
        }
        return 0
    }

}
