//
//  SearchRichViewController.swift
//  faer
//
//  Created by pluto on 30.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import MapKit

class RichSearchViewController: UIViewController {
    
    static let storyboardName: String = "RichSearchView"
    
    static let storyboardID: String = "RichSearchViewController"
    
    @IBOutlet weak var searchBtn: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var presentQuery: Any? // used for app notifications
    
    private var dataSourceSections: [RichSection]?
    
    private lazy var refreshControl = UIRefreshControl()
    
    private lazy var gender: User.Gender = User.shared.gender // used to detect gender changes
    
    private var isRefreshing: Bool = false
    
    private var lastKnownLocation: CLLocation?
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.setNeedsStatusBarAppearanceUpdate()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil) // get notified when app moves to foregground
        NotificationCenter.default.addObserver(self, selector: #selector(updateMapTeasers), name: .userLocationUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDataSource), name: .userGenderUpdated, object: nil)

        // handle app notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentProduct, object: nil) // handle product alerts
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentSearchResult, object: nil) // handle brand alerts

        self.configureCollectionView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setNeedsStatusBarAppearanceUpdate()
        
        if self.gender != User.shared.gender {
            self.gender = User.shared.gender
            self.updateDataSource()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let query = self.presentQuery {
            self.performSegue(withIdentifier: CommonSegues.searchResult.rawValue, sender: query)
        }
        
        if dataSourceSections == nil {
            self.updateDataSource()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.presentQuery = nil
    }
    
    
    @objc
    private func handle(notification: NSNotification) {
        guard self.isVisible() else { return }
        
        guard let userInfo = AppNotifications.UserInfo(notification.userInfo) else { return }
        
        self.performSegue(withIdentifier: userInfo.segue.rawValue, sender: userInfo.payload)
    }
    
    @objc
    private func appMovedToForeground() {
         self.updateDataSource()
    }
    
    @objc
    private func updateMapTeasers() {
        guard
            let _ = self.dataSourceSections,
            let _ = User.shared.lastLocation
        else {
            return
        }
        
        if let storedLocation = CLLocation.readFromUserDefaults() {
            if storedLocation.distance(from: User.shared.lastLocation!) < 100 { // don't update if moved less than 100m
                return
            }
        }
        
        User.shared.lastLocation!.saveToUserDefaults()
        
        Stores.using(location: User.shared.lastLocation!, completion: { [weak self] (stores, error) in
            
            guard let strongSelf = self else {
                return
            }

            DispatchQueue.main.async {
                for (index, section) in strongSelf.dataSourceSections!.enumerated() where section is MapTeaserSection {
                    (section as! MapTeaserSection).dataSource = stores
                    self?.collectionView.reloadSections([index])
                }
            }
        })
        
    }
    
    func configureCollectionView() {
        
        //register content cells
        
        self.collectionView.register(UINib(nibName: MapTeaserCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: MapTeaserCollectionViewCell.reuseIdentifier)
        self.collectionView.register(UINib(nibName: BrandSpotlightItemCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: BrandSpotlightItemCollectionViewCell.reuseIdentifier)
        self.collectionView.register(UINib(nibName: PopularCategoryCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: PopularCategoryCollectionViewCell.reuseIdentifier)
        self.collectionView?.register(UINib(nibName: SettingsCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: SettingsCollectionViewCell.reuseIdentifier)
        // accesories
        
        self.collectionView.register(UINib(nibName: RichSectionLoadingCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: RichSectionLoadingCollectionViewCell.reuseIdentifier)
        
        self.collectionView.register(UINib(nibName: DiscoverCollectionFooterReusableView.nibName, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter , withReuseIdentifier: DiscoverCollectionFooterReusableView.reuseIdentifer)
        collectionView.register(RichSearchSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: RichSearchSectionHeaderView.reuseIdentifier)
        
        // handler for refresh control
        refreshControl.addTarget(self, action: #selector(self.updateDataSource), for: .valueChanged)
        self.collectionView.refreshControl = refreshControl
        
        self.updateDataSource()
        
    }
    
    @objc
    private func updateDataSource() {
        
        guard !isRefreshing else { return }
        
        self.isRefreshing = true
        
        var location: CLLocation? = CLLocation.readFromUserDefaults()
        
        if let _ = User.shared.lastLocation {
            location = User.shared.lastLocation
            location?.saveToUserDefaults()
        }
        
        RichSearchViewDataSource.using(location: location, parent: self.collectionView) { [weak self] (richSections, error) in
            
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
            }
            
            self?.dataSourceSections = [SettingsSection(parent: self?.collectionView)]
            
            guard error == nil else {
                self?.isRefreshing = false
                return
            }
                        
            if let _ = richSections {
                for section in richSections! {
                    self?.dataSourceSections?.append(section)
                    section.delegate = self
                }
            }
            
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
                self?.isRefreshing = false
            }
            
        }
        
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        CommonSeguesManager.prepare(for: segue, sender: sender)
    }
    
    
}

extension RichSearchViewController: UICollectionViewDataSource {
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSourceSections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSourceSections?[section].totalItems ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard
            let _ = self.dataSourceSections,
            self.dataSourceSections!.indices.contains(indexPath.section),
            let section = self.dataSourceSections?[indexPath.section],
            !section.isLoading
            else {
                
                let cell: RichSectionLoadingCollectionViewCell = collectionView.dequeueCell(RichSectionLoadingCollectionViewCell.reuseIdentifier, indexPath: indexPath) as! RichSectionLoadingCollectionViewCell
                return cell
                
        }
        
        return section.cell(at: indexPath, collectionView: collectionView)
        
    }
    
}

extension RichSearchViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard
            let _ = self.dataSourceSections,
            self.dataSourceSections!.indices.contains(indexPath.section),
            let section = dataSourceSections?[indexPath.section]
            else {
                return
        }
        
        section.segue(at: indexPath)
        
        return
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header: RichSearchSectionHeaderView = collectionView.dequeueSupplementary(RichSearchSectionHeaderView.reuseIdentifier, indexPath: indexPath, kind: kind) as! RichSearchSectionHeaderView
            
            guard
                let _ = self.dataSourceSections,
                self.dataSourceSections!.indices.contains(indexPath.section),
                let name = self.dataSourceSections?[indexPath.section].name
            else {
                return header
            }
            
            header.title = name
            
            return header
        case UICollectionView.elementKindSectionFooter:
            let footer: DiscoverCollectionFooterReusableView = collectionView.dequeueSupplementary(DiscoverCollectionFooterReusableView.reuseIdentifer, indexPath: indexPath, kind: kind) as! DiscoverCollectionFooterReusableView
            
            if self.dataSourceSections?[indexPath.section].totalItems == nil {
                footer.activityView.isHidden = false
                footer.noInternetInfo.isHidden = true
                return footer
            }
            
            if !Network.shared.isReachable() {
                footer.activityView.isHidden = true
                footer.noInternetInfo.isHidden = false
            } else {
                footer.activityView.isHidden = false
                footer.noInternetInfo.isHidden = true
            }
            return footer
        default:
            // must not happen, return dummyView to avoid crash
            let header: RichSearchSectionHeaderView = collectionView.dequeueSupplementary(RichSearchSectionHeaderView.reuseIdentifier, indexPath: indexPath, kind: kind) as! RichSearchSectionHeaderView
            return header
        }
    }
}

extension RichSearchViewController: UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let defaultHeight: CGSize = CGSize(width: collectionView.bounds.width, height: 60)
        
        guard let currentSection = self.dataSourceSections?[section], let referenceHeightForSectionHeader = currentSection.referenceHeightForSectionHeader() else {
            return defaultHeight
        }
        
        
        return CGSize(width: collectionView.bounds.width, height: referenceHeightForSectionHeader)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        return CGSize.zero
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let currentSection = self.dataSourceSections?[indexPath.section], !currentSection.isLoading else {
            return CGSize(width: self.collectionView.bounds.width, height: 200)
        }
        
        guard let _ = currentSection.totalItems, currentSection.totalItems! > 0 else {
            return CGSize.zero
        }
        
        let minimumInteritemSpacing: CGFloat
        
        if let layout: UICollectionViewFlowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            minimumInteritemSpacing = layout.minimumInteritemSpacing
        } else {
            minimumInteritemSpacing = 10
        }
        
        return currentSection.sizeForItem(minimumInteritemSpacing: minimumInteritemSpacing, maxSize: collectionView.bounds.size)
    }
    
}

extension RichSearchViewController: RichSectionDelegate {
    
    func hideMap(requestBy section: RichSection) {
        guard let sectionIndex = section.section else { return }
        DispatchQueue.main.async {
            self.collectionView.reloadSections([sectionIndex])
        }
    }
    
    func share(sender: UIView, for item: Item) {
        let activityViewController = UIActivityViewController(
            activityItems: [item.shareUrl],
            applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = sender
        activityViewController.popoverPresentationController?.sourceRect = sender.bounds
        
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
            guard completed else { return }
            let itemParameters: [String: Any] = Log.serialize(item) // pass by value to avoid retention cycle in AV completion closure
            Log.Tap.share(view: .SearchResult, parameters: itemParameters)
        }
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
}


extension CLLocation {
    
    private static func userDefaultKeys() -> (latitude: String, longitude: String) {
        return ("LocationLatKey", "LocationLonKey")
    }
    
    func saveToUserDefaults() {
        
        UserDefaults.standard.set(self.coordinate.latitude, forKey: CLLocation.userDefaultKeys().latitude)

        UserDefaults.standard.set(self.coordinate.longitude, forKey: CLLocation.userDefaultKeys().longitude)
        
    }
    
    static func readFromUserDefaults() -> CLLocation? {
    
        guard
            let lat = UserDefaults.standard.object(forKey: CLLocation.userDefaultKeys().latitude) as? Double,
            let lon = UserDefaults.standard.object(forKey: CLLocation.userDefaultKeys().longitude) as? Double
        else {
                return nil
        }
        
        return CLLocation(latitude: lat, longitude: lon)
    
    }
    
    
}
